#!/usr/bin/env python3
"""Build a bounded, macOS-specific public app index from GitHub Releases.

Runs in GitHub Actions, not on every user's Mac. Only records GitHub repositories
with at least one recognizable *macOS release asset*. This is a package-presence
check, NOT a signature/notarization, developer, quality or security audit.

No content or code is copied from a competing app store.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import json
import os
import pathlib
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

BASE = "https://api.github.com"
ROOT = pathlib.Path(__file__).resolve().parents[1]
SEEDS = ROOT / "scripts" / "catalog-seeds.json"
OUTPUT = ROOT / "data" / "catalog-index.json"
VERSION = 1
UTC = dt.timezone.utc
NOW = dt.datetime.now(UTC)
MAX_CANDIDATES = 520
MAX_CHECKS = 260
MAX_ENTRIES = 1250
RECHECK_AFTER_DAYS = 12
MAX_AGE_DAYS = 45
SEARCHES = [
    ("Jeux", "topic:game topic:macos stars:>30 archived:false"),
    ("Jeux", "topic:macos-game stars:>10 archived:false"),
    ("Jeux", "game macos in:description stars:>60 archived:false"),
    ("Jeux", "topic:open-source-game stars:>100 archived:false"),
    ("Jeux", "topic:game topic:desktop stars:>80 archived:false"),
    ("Lanceurs & émulation", "topic:emulator topic:macos stars:>50 archived:false"),
    ("Lanceurs & émulation", "topic:game-launcher stars:>30 archived:false"),
    ("Lanceurs & émulation", "macos emulator in:description stars:>150 archived:false"),
    ("Productivité", "topic:macos topic:productivity stars:>100 archived:false"),
    ("Utilitaires", "topic:macos topic:app stars:>100 archived:false"),
    ("Graphisme", "topic:macos topic:graphics stars:>30 archived:false"),
    ("Audio & musique", "topic:macos topic:audio stars:>100 archived:false"),
    ("Développement", "topic:macos topic:developer-tools stars:>100 archived:false"),
    ("Internet", "topic:macos topic:browser stars:>100 archived:false"),
    ("Multimédia", "topic:macos topic:video stars:>100 archived:false"),
    ("Sécurité", "topic:macos topic:security stars:>100 archived:false"),
    ("Réseau", "topic:macos topic:network stars:>100 archived:false"),
    ("Bureautique", "topic:macos topic:notes stars:>100 archived:false"),
    ("Éducation", "topic:macos topic:education stars:>100 archived:false"),
    ("Personnalisation", "topic:macos topic:customization stars:>100 archived:false"),
    ("Utilitaires", "macos app in:description stars:>1500 archived:false"),
]
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
EXCLUDED = ("windows", "win32", "linux", "android", "source", "src-", "symbols", "debug",
            "checksum", ".sha", ".asc", ".sig", "portable.exe", "setup.exe")
LAUNCHER_HINTS = ("emulator", "launcher", "rom-manager", "game-launcher")
ENGINE_HINTS = ("game-engine", "game-development", "game-framework", "engine")
GOOD_LICENSES = None  # No license based gate: license remains visible in UI.


def is_macos_asset(name: str) -> bool:
    lower = name.lower()
    if any(word in lower for word in EXCLUDED):
        return False
    mac = any(word in lower for word in ("macos", "mac-", "mac_", "darwin", "osx", "apple-silicon", ".app"))
    if lower.endswith((".dmg", ".pkg")):
        return True
    if lower.endswith(".zip") and mac:
        return True
    return False


def classify(category: str, repo: dict, seeded: bool) -> str:
    """Separate playable games from engines, launchers and game dev tools."""
    if category != "Jeux":
        return category
    topics = set(repo.get("topics") or ())
    name = ((repo.get("name") or "") + " " + (repo.get("description") or "")).lower()
    if topics.intersection(ENGINE_HINTS) or "game engine" in name:
        return "Développement"
    # Runnable game engines requiring proprietary data and game-porting tools
    # are not standalone games; keep them out of the playable games category.
    if topics.intersection(LAUNCHER_HINTS) or any(token in name for token in
            ("emulator", "emulation", "launcher", "minecraft launcher",
             "frontend for", "port builder", "porting tool", "one-click macos app",
             "open-source engine for", "source engine for", "game assets required",
             "bring your own game")):
        return "Lanceurs & émulation"
    return category


def api(path: str, attempts=3) -> dict | list | None:
    endpoint = BASE + path
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "OrbitStore-Index/1.0"}
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = "Bearer " + token
    for attempt in range(attempts):
        request = urllib.request.Request(endpoint, headers=headers)
        try:
            with urllib.request.urlopen(request, timeout=23) as stream:
                return json.loads(stream.read(7_000_000).decode("utf-8"))
        except urllib.error.HTTPError as err:
            if err.code in (404, 410, 422):
                return None
            if err.code in (403, 429, 500, 502, 503) and attempt + 1 < attempts:
                # Back off on secondary limits instead of hammering GitHub.
                wait = 2 ** attempt + (2 if err.code in (403, 429) else 0)
                time.sleep(wait)
                continue
            raise RuntimeError(f"GitHub HTTP {err.code} for {path}") from err
        except (urllib.error.URLError, TimeoutError):
            if attempt + 1 == attempts:
                raise
            time.sleep(2 ** attempt)
    return None


def normalize_repo(entry: dict, category: str, verified_at: str, tag: str,
                   asset: str, is_seed: bool) -> dict:
    repo = entry["full_name"]
    return {
        "repo": repo,
        "name": entry.get("display_name") or entry.get("name") or repo.split("/")[-1],
        "category": classify(category, entry, is_seed),
        "summary": (entry.get("description") or "").strip()[:320],
        "stars": int(entry.get("stargazers_count") or 0),
        "language": entry.get("language"),
        "license": (entry.get("license") or {}).get("spdx_id"),
        "homepage": entry.get("homepage") or "",
        "updated_at": entry.get("pushed_at") or entry.get("updated_at"),
        "release_tag": tag,
        "asset_name": asset,
        "verified_at": verified_at,
        "source": "GitHub release",
    }


def load_previous() -> dict[str, dict]:
    if not OUTPUT.is_file():
        return {}
    try:
        document = json.loads(OUTPUT.read_text(encoding="utf-8"))
        if document.get("schema") != VERSION:
            return {}
        return {item["repo"].casefold(): item for item in document.get("entries", [])
                if REPO_RE.match(item.get("repo", ""))}
    except (OSError, ValueError, KeyError):
        return {}


def recent(item: dict, max_age: int) -> bool:
    try:
        stamp = dt.datetime.fromisoformat(item["verified_at"].replace("Z", "+00:00"))
        return (NOW - stamp).days < max_age
    except (KeyError, ValueError, TypeError):
        return False


def search_candidates() -> dict[str, tuple[dict, str]]:
    candidates = {}
    failures = 0
    for category, query in SEARCHES:
        params = urllib.parse.urlencode({
            "q": query, "sort": "stars", "order": "desc", "per_page": "75",
        })
        try:
            response = api("/search/repositories?" + params)
        except Exception as err:
            failures += 1
            print(f"Search skipped ({category}): {err}", file=sys.stderr)
            if failures >= 4:
                break
            continue
        if not isinstance(response, dict):
            continue
        for item in response.get("items", []):
            repo = item.get("full_name") or ""
            if not REPO_RE.match(repo) or item.get("archived") or item.get("fork"):
                continue
            key = repo.casefold()
            if key not in candidates:
                candidates[key] = (item, category)
        # Every query may be re-run on another day. Avoid burst limits.
        time.sleep(0.8)
    return candidates


def verify_one(item: dict, category: str, previous: dict | None,
               is_seed: bool) -> dict | None:
    repo = item["full_name"]
    # Do not hammer the Releases API for previously verified entries.
    if previous and recent(previous, RECHECK_AFTER_DAYS):
        # Preserve verified asset status while updating discovery metadata.
        return normalize_repo(item, category, previous["verified_at"],
                              previous["release_tag"], previous["asset_name"], is_seed)
    try:
        encoded = "/".join(urllib.parse.quote(segment, safe="") for segment in repo.split("/"))
        releases = api(f"/repos/{encoded}/releases?per_page=4")
        if not isinstance(releases, list):
            return None
        for release in releases:
            if release.get("draft") or not isinstance(release.get("assets"), list):
                continue
            mac_assets = [asset.get("name", "") for asset in release["assets"]
                          if is_macos_asset(asset.get("name", ""))]
            if mac_assets:
                return normalize_repo(item, category, NOW.isoformat(), release.get("tag_name", ""),
                                      mac_assets[0], is_seed)
    except Exception as err:
        # Carry only recent, previously verified entries on temporary network errors.
        print(f"Release check failed ({repo}): {err}", file=sys.stderr)
        if previous and recent(previous, MAX_AGE_DAYS):
            return previous
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed-only", action="store_true")
    args = parser.parse_args()
    previous = load_previous()
    seed_records = json.loads(SEEDS.read_text(encoding="utf-8"))
    seeds = {}
    for seed in seed_records:
        repo = seed["repo"]
        if REPO_RE.match(repo):
            seeds[repo.casefold()] = seed
    discovery = {} if args.seed_only else search_candidates()
    print(f"Seeds={len(seeds)}, search candidates={len(discovery)}, previous={len(previous)}")
    selected = {}
    # Curated entries get priority in verification; category labels are reviewed.
    for key, seed in seeds.items():
        if key in discovery:
            metadata, _ = discovery[key]
            metadata = dict(metadata)
            metadata["display_name"] = seed.get("name") or metadata.get("name")
        else:
            try:
                metadata = api("/repos/" + seed["repo"])
            except Exception as err:
                print(f"Seed unavailable ({seed['repo']}): {err}", file=sys.stderr)
                metadata = None
            if not isinstance(metadata, dict):
                continue
            metadata = dict(metadata)
            metadata["display_name"] = seed.get("name") or metadata.get("name")
        selected[key] = (metadata, seed["category"], True)
    # Rotation: projects seen last time continue to be discoverable and rechecked
    # over subsequent runs; new popular projects get a share of the budget.
    for key, (metadata, category) in discovery.items():
        if key not in selected:
            selected[key] = (metadata, category, False)
    ordered = list(selected.items())
    old = [pair for pair in ordered if pair[0] in previous]
    new = [pair for pair in ordered if pair[0] not in previous]
    # Check stale known projects first, then popular newly discovered ones.
    old.sort(key=lambda p: (recent(previous[p[0]], RECHECK_AFTER_DAYS),
                            -int(p[1][0].get("stargazers_count") or 0)))
    new.sort(key=lambda p: -int(p[1][0].get("stargazers_count") or 0))
    budget = max(0, MAX_CHECKS - len(seeds))
    work = [(key, value) for key, value in ordered if key in seeds]
    work += [pair for pair in old + new if pair[0] not in seeds][:budget]
    results = dict(previous)
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        tasks = {pool.submit(verify_one, data, category, previous.get(key), is_seed): key
                 for key, (data, category, is_seed) in work[:MAX_CANDIDATES]}
        for task in concurrent.futures.as_completed(tasks):
            key = tasks[task]
            try:
                entry = task.result()
                if entry:
                    results[key] = entry
                else:
                    results.pop(key, None)
            except Exception as err:
                print(f"Unexpected verification error ({key}): {err}", file=sys.stderr)
    results = {key: value for key, value in results.items()
               if recent(value, MAX_AGE_DAYS) and is_macos_asset(value.get("asset_name", ""))}
    # Favor actual games in the game section; categorize emulators/engines separately.
    ordered_entries = sorted(results.values(),
                             key=lambda e: (-int(e.get("stars") or 0), e["repo"].casefold()))[:MAX_ENTRIES]
    if len(ordered_entries) < 5:
        raise RuntimeError("Insufficient verified macOS entries; keeping existing index.")
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    document = {
        "schema": VERSION,
        "generated_at": NOW.isoformat(),
        "count": len(ordered_entries),
        "categories": {category: sum(e["category"] == category for e in ordered_entries)
                       for category in sorted({e["category"] for e in ordered_entries})},
        "entries": ordered_entries,
    }
    OUTPUT.write_text(json.dumps(document,ensure_ascii=False,separators=(",",":"))+"\n",
                      encoding="utf-8")
    print(f"Verified {len(ordered_entries)} macOS release entries into {OUTPUT}")
    for category, count in sorted(document["categories"].items()):
        print(f"  {category}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
