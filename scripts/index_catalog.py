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
REJECTED = ROOT / "data" / "catalog-rejected.json"
VERSION = 1
UTC = dt.timezone.utc
NOW = dt.datetime.now(UTC)
MAX_CANDIDATES = 800
MAX_CHECKS = 480
MAX_ENTRIES = 1250
RECHECK_AFTER_DAYS = 12
MAX_AGE_DAYS = 45
SEARCHES = [
    ("Jeux", "topic:game topic:macos stars:>30 archived:false"),
    ("Jeux", "topic:macos-game stars:>10 archived:false"),
    ("Jeux", "game macos in:description stars:>60 archived:false"),
    ("Jeux", "topic:open-source-game stars:>100 archived:false"),
    ("Jeux", "topic:game topic:desktop stars:>80 archived:false"),
    ("Jeux", "topic:indie-game topic:macos stars:>15 archived:false"),
    ("Jeux", "macos game download in:description stars:>20 archived:false"),
    ("Jeux", "topic:open-source-game topic:macos stars:>10 archived:false"),
    ("Jeux", "topic:indie-game stars:>400 archived:false"),
    ("Graphisme", "topic:image-editor topic:macos stars:>40 archived:false"),
    ("Création", "topic:video-editor topic:macos stars:>40 archived:false"),
    ("Audio & musique", "topic:music-player topic:macos stars:>40 archived:false"),
    ("Lanceurs & émulation", "topic:emulator topic:macos stars:>50 archived:false"),
    ("Lanceurs & émulation", "topic:game-launcher stars:>30 archived:false"),
    ("Lanceurs & émulation", "macos emulator in:description stars:>150 archived:false"),
    ("Lanceurs & émulation", "topic:emulator stars:>500 archived:false"),
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
    ("Bureautique", "topic:macos topic:office stars:>100 archived:false"),
    ("Bureautique", "topic:markdown-editor topic:macos stars:>100 archived:false"),
    ("Bureautique", "topic:note-taking topic:macos stars:>100 archived:false"),
    ("Bureautique", "desktop office editor macOS in:description stars:>100 archived:false"),
    ("Éducation", "topic:macos topic:education stars:>100 archived:false"),
    ("Personnalisation", "topic:macos topic:customization stars:>100 archived:false"),
    ("Utilitaires", "macos app in:description stars:>1500 archived:false"),
]
REPO_RE = re.compile(r"^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$")
EXCLUDED = ("windows", "win32", "linux", "android", "freebsd", "openbsd", "netbsd",
            "source", "src-", "symbols", "dsym", "debug", "terminal-only",
            "console-only", "headless", "cli-only", "dont-use", "do-not-use", "checksum", ".sha", ".asc",
            ".sig", "portable.exe", "setup.exe")
LAUNCHER_HINTS = ("emulator", "launcher", "rom-manager", "game-launcher")
ENGINE_HINTS = ("game-engine", "game-development", "game-framework", "engine")
GOOD_LICENSES = None  # No license based gate: license remains visible in UI.
# A small editorial weight improves discovery; it does not override release
# verification. New entries must still publish a macOS package.
# Editorial relevance is deliberately not interchangeable with GitHub stars.
# Only verified macOS release assets reach the installable feed.
FEATURED_REPOS = {
    "supertuxkart/stk-code":125, "openra/openra":124,
    "wesnoth/wesnoth":122, "warzone2100/warzone2100":121,
    "openttd/openttd":119, "mindustrygame/mindustry":118,
    "widelands/widelands":117, "endless-sky/endless-sky":115,
    "supertux/supertux":114, "freeorion/freeorion":112,
    "beyond-all-reason/beyond-all-reason":111,
    "drwhut/tabletop-club":105, "yairm210/unciv":106,
    "hedgewars/hw":110, "openrct2/openrct2":105,
    "ddnet/ddnet":103, "ppy/osu":99,
    "iina/iina":115, "handbrake/handbrake":113,
    "localsend/localsend":116, "obsproject/obs-studio":116,
    "jgraph/drawio-desktop":121, "obsidianmd/obsidian-releases":119,
    "logseq/logseq":117, "zettlr/zettlr":115,
    "marktext/marktext":112, "toeverything/affine":113,
    "koodo-reader/koodo-reader":108,
    "libresprite/libresprite":101, "upscayl/upscayl":111,
    "appflowy-io/appflowy":112, "laurent22/joplin":114,
    "standardnotes/app":110, "siyuan-note/siyuan":109,
    "storytold/photocraft":95, "storytold/vectorcraft":94,
    "storytold/filmcraft":92, "storytold/pdfcraft":93,
    "simohypers/limusic":96, "darktable-org/darktable":107,
    "actualbudget/actual":109, "mifi/lossless-cut":107,
    "exelban/stats":106, "keepassxreboot/keepassxc":110,
    "rustdesk/rustdesk":108,
}

# Genre taxonomy is about what a game offers, not its source-code tags.
GAME_GENRES = {
    "supertuxkart/stk-code":"Course", "openra/openra":"Stratégie",
    "wesnoth/wesnoth":"Stratégie", "warzone2100/warzone2100":"Stratégie",
    "mindustrygame/mindustry":"Stratégie", "beyond-all-reason/beyond-all-reason":"Stratégie",
    "openttd/openttd":"Gestion", "widelands/widelands":"Gestion",
    "openrct2/openrct2":"Gestion", "openloco/openloco":"Gestion",
    "freeorion/freeorion":"Stratégie", "0ad/0ad":"Stratégie",
    "endless-sky/endless-sky":"Simulation", "hedgewars/hw":"Stratégie",
    "supertux/supertux":"Action", "ddnet/ddnet":"Action",
    "ppy/osu":"Rythme", "shatteredpixel/shattered-pixel-dungeon":"Rôle",
    "cleverraven/cataclysm-dda":"Rôle", "crawl/crawl":"Rôle",
    "luanti-org/luanti":"Simulation", "classicube/classicube":"Simulation",
    "drwhut/tabletop-club":"Jeux de plateau", "yairm210/unciv":"Stratégie",
}
# Explicit reviewed path: unlike README badges, this is a real app icon.
ICON_PATH_HINTS = {
    "supertuxkart/stk-code":"data/supertuxkart_512.png",
}
MAX_ICON_SCANS = 36
ICON_RECHECK_DAYS = 35


def game_genre(repo: str, category: str, description: str = "") -> str | None:
    if category != "Jeux":
        return None
    key = repo.casefold()
    if key in GAME_GENRES:
        return GAME_GENRES[key]
    words = description.casefold()
    if any(k in words for k in ("chess", "board game", "tabletop", "cards")):
        return "Jeux de plateau"
    if any(k in words for k in ("strategy", "rts", "turn-based", "tactical", "warfare")):
        return "Stratégie"
    if any(k in words for k in ("city builder", "management", "tycoon", "colony")):
        return "Gestion"
    if any(k in words for k in ("racing", "kart")):
        return "Course"
    if any(k in words for k in ("role-playing", "roguelike", "rpg")):
        return "Rôle"
    if any(k in words for k in ("simulation", "sandbox")):
        return "Simulation"
    return "Action"


def score_icon_path(path: str, display_name: str) -> int:
    """Prefer application branding over badges, UI controls and screenshots."""
    lower = path.casefold()
    filename = lower.rsplit("/", 1)[-1]
    if not filename.endswith((".png", ".jpg", ".jpeg", ".ico", ".icns")):
        return -1
    if any(part in lower for part in (
            "test/", "docs/screenshots", "screenshot", "badge", "shield",
            "toolbar", "button", "spinner", "back.png", "loading",
            "third_party/", "third-party/", "vendor/", "node_modules/",
            ".github/", "licenses", "playstore", "appstore")):
        return -1
    canonical = re.sub(r"[^a-z0-9]", "", display_name.casefold())
    stem = re.sub(r"[^a-z0-9]", "", filename.rsplit(".", 1)[0])
    score = 0
    if canonical and len(canonical) > 3 and canonical in stem:
        score += 85
    if "appicon" in stem or "applicationicon" in stem:
        score += 95
    elif "logo" in stem:
        score += 55
    elif "icon" in stem:
        score += 45
    else:
        score += 5
    if any(dim in stem for dim in ("1024", "512", "256")):
        score += 32
    if filename.endswith(".icns"):
        score += 20
    if lower.startswith(("data/", "assets/", "resources/", "res/")):
        score += 14
    if filename in ("icon.png", "logo.png") and path.count("/") > 2:
        score -= 30
    return score if score >= 55 else -1


def discover_icon_url(item: dict) -> str | None:
    """One bounded server-side Git tree lookup, never one API request per user."""
    repo = item["repo"]
    branch = item.get("default_branch") or "main"
    hint = ICON_PATH_HINTS.get(repo.casefold())
    if hint:
        path = hint
    else:
        tree = api("/repos/" + repo + "/git/trees/" +
                   urllib.parse.quote(branch, safe="") + "?recursive=1", attempts=1)
        if not isinstance(tree, dict) or not isinstance(tree.get("tree"), list):
            return None
        images = ((score_icon_path(f.get("path", ""), item["name"]), f.get("path", ""))
                  for f in tree["tree"] if f.get("type") == "blob")
        rank, path = max(images, default=(-1, ""))
        if rank < 55:
            return None
    return ("https://raw.githubusercontent.com/" + repo + "/" +
            urllib.parse.quote(branch, safe="") + "/" +
            urllib.parse.quote(path, safe="/"))



def is_macos_asset(name: str) -> bool:
    """Conservative filename gate (not a signature or content verification)."""
    lower = name.lower()
    if any(word in lower for word in EXCLUDED):
        return False
    mac = any(word in lower for word in ("macos", "mac-", "mac_", "darwin",
                                         "osx", "apple-silicon", ".app", "universal"))
    if lower.endswith(".dmg"):
        return True
    if lower.endswith(".pkg"):
        return mac  # .pkg can also be FreeBSD; require a macOS indicator.
    if lower.endswith(".zip"):
        return mac and not lower.endswith((".dsym.zip", ".symbols.zip"))
    return False


DEVELOPER_HINTS = (
    "command line", "command-line", "cli tool", "terminal app", "terminal utility",
    "framework", "library for", "software development kit", "developer tool",
    "docker", "kubernetes", "self-hosted server", "api server",
    "reverse proxy", "game engine", "game framework", "porting toolkit",
    "debugger", "electron wrapper", "code editor", "ssh client",
)
DEVELOPER_REPOS = {
    "tw93/pake", "codeeditapp/codeedit", "kivy/kivy", "xtool-org/xtool",
    "sunshinestream/sunshine", "fleetdm/fleet", "sxyazi/yazi",
    "wavetermdev/waveterm", "lencx/chatgpt", "jarvis322/macos-sysdata",
}
CONSUMER_REPOS = {
    "iina/iina", "handbrake/handbrake", "obsproject/obs-studio",
    "keepassxreboot/keepassxc", "cryptomator/cryptomator",
    "localsend/localsend", "rustdesk/rustdesk", "openrct2/openrct2",
    "supertuxkart/stk-code", "ppy/osu", "exelban/stats",
    "moonlight-stream/moonlight-qt", "standardnotes/app",
    "brave/brave-browser",
    "storytold/photocraft","storytold/vectorcraft","storytold/filmcraft",
    "storytold/pdfcraft","simohypers/limusic","actualbudget/actual",
}


def classify_audience(repo: dict, category: str, asset: str) -> str:
    """Hide technical projects unless developer mode is enabled."""
    key = (repo.get("full_name") or "").casefold()
    if key in CONSUMER_REPOS:
        return "consumer"
    if key in DEVELOPER_REPOS or category == "Développement":
        return "developer"
    description = ((repo.get("name") or "") + " " +
                   (repo.get("description") or repo.get("summary") or "")).lower()
    if any(hint in description for hint in DEVELOPER_HINTS):
        return "developer"
    if any(hint in asset.lower() for hint in ("-cli", "_cli", "terminal",
                                               "console", ".dsym", "-inso-")):
        return "developer"
    if category == "Jeux" and any(hint in description for hint in
                                    ("cheat", "tier list", "modding tool", "trainer",
                                     "game engine", "game mod manager")):
        return "developer"
    if category == "Lanceurs & émulation":
        return "developer"
    if category == "Réseau" and key not in {
        "localsend/localsend", "rustdesk/rustdesk"
    }:
        return "developer"
    return "consumer"


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
                   asset: str, is_seed: bool, assets: list[str] | None = None) -> dict:
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
        "default_branch": entry.get("default_branch") or "",
        "updated_at": entry.get("pushed_at") or entry.get("updated_at"),
        "release_tag": tag,
        "asset_name": asset,
        "asset_names": list(dict.fromkeys((assets or [asset])[:40])),
        "audience": classify_audience(entry, classify(category, entry, is_seed), asset),
        "verified_at": verified_at,
        "source": "GitHub release",
        "editorial_rank": FEATURED_REPOS.get(repo.casefold(),0),
        "genre": game_genre(repo, classify(category, entry, is_seed),
                            entry.get("description") or ""),
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


def load_rejected() -> dict[str, str]:
    """Short-lived cache of repositories with no known Mac build."""
    try:
        payload=json.loads(REJECTED.read_text(encoding="utf-8"))
        if payload.get("schema")!=VERSION:
            return {}
        return {key:time for key,time in payload.get("entries",{}).items()
                if REPO_RE.match(key) and isinstance(time,str)}
    except (OSError,ValueError,TypeError):
        return {}


def is_recent_rejection(timestamp:str,days:int=9)->bool:
    try:
        observed=dt.datetime.fromisoformat(timestamp.replace("Z","+00:00"))
        return 0<=(NOW-observed).total_seconds()<days*86400
    except (ValueError,TypeError):
        return False


def recent(item: dict, max_age: int) -> bool:
    try:
        stamp = dt.datetime.fromisoformat(item["verified_at"].replace("Z", "+00:00"))
        return (NOW - stamp).days < max_age
    except (KeyError, ValueError, TypeError):
        return False


def search_candidates() -> dict[str, tuple[dict, str]]:
    candidates = {}
    failures = 0
    for index,(category, query) in enumerate(SEARCHES):
        pages=[1]
        # Across three days inspect deeper pages for a rotating subset of
        # queries, instead of querying 1,000 results on every user's Mac.
        if index % 3 == NOW.toordinal() % 3:
            pages.append(2 + (NOW.toordinal() // 3) % 3)
        for page in pages:
            params=urllib.parse.urlencode({
                "q":query,"sort":"stars","order":"desc",
                "per_page":"75","page":str(page),
            })
            try:
                response=api("/search/repositories?"+params)
            except Exception as err:
                failures+=1
                print(f"Search skipped ({category}, page {page}): {err}",file=sys.stderr)
                if failures>=4:
                    return candidates
                continue
            if isinstance(response,dict):
                for item in response.get("items",[]):
                    repo=item.get("full_name") or ""
                    if not REPO_RE.match(repo) or item.get("archived") or item.get("fork"):
                        continue
                    candidates.setdefault(repo.casefold(),(item,category))
            # Keep authenticated GitHub Search within its minute-based quota.
            time.sleep(1.6)
    return candidates


def verify_one(item: dict, category: str, previous: dict | None,
               is_seed: bool) -> dict | None:
    repo = item["full_name"]
    # Do not hammer the Releases API for previously verified entries.
    if previous and recent(previous, RECHECK_AFTER_DAYS):
        # Preserve verified asset status while updating discovery metadata.
        return normalize_repo(item, category, previous["verified_at"],
                              previous["release_tag"], previous["asset_name"], is_seed,
                              previous.get("asset_names") or [previous["asset_name"]])
    try:
        encoded = "/".join(urllib.parse.quote(segment, safe="") for segment in repo.split("/"))
        releases = api(f"/repos/{encoded}/releases?per_page=4")
        if not isinstance(releases, list):
            return None
        # Prefer non-prerelease packages; keep beta only when no stable macOS
        # build exists. Rank formats so a real DMG wins over a ZIP or PKG.
        ranked = sorted((release for release in releases if not release.get("draft")),
                        key=lambda release:bool(release.get("prerelease")))
        for release in ranked:
            if not isinstance(release.get("assets"),list):
                continue
            candidates = [asset for asset in release["assets"]
                          if is_macos_asset(asset.get("name",""))
                          and asset.get("state","uploaded")=="uploaded"
                          and (asset.get("size") or 0) >= 100_000]
            candidates.sort(key=lambda asset:(
                not asset["name"].lower().endswith(".dmg"),
                not asset["name"].lower().endswith(".zip"),
                -(asset.get("download_count") or 0)))
            if candidates:
                names=[asset["name"] for asset in candidates]
                result=normalize_repo(item, category, NOW.isoformat(),
                                      release.get("tag_name",""), names[0], is_seed, names)
                result["downloads"]=sum(asset.get("download_count") or 0 for asset in candidates)
                result["prerelease"]=bool(release.get("prerelease"))
                return result
    except Exception as err:
        # Carry only recent, previously verified entries on temporary network errors.
        print(f"Release check failed ({repo}): {err}", file=sys.stderr)
        if previous and recent(previous, MAX_AGE_DAYS):
            return previous
        raise
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--seed-only", action="store_true")
    args = parser.parse_args()
    previous = load_previous()
    rejected = load_rejected()
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
    # Always reserve capacity for *new* discoveries. Otherwise, once the
    # cached index grows beyond the daily budget it never grows again.
    old_extra = [pair for pair in old if pair[0] not in seeds]
    new_extra = [pair for pair in new if pair[0] not in seeds
                 and not is_recent_rejection(rejected.get(pair[0],""))]
    review_slots = min(len(old_extra), int(budget * 0.40))
    fresh_slots = max(0, budget - review_slots)
    work += old_extra[:review_slots] + new_extra[:fresh_slots]
    if len(new_extra) < fresh_slots:
        work += old_extra[review_slots:review_slots + fresh_slots - len(new_extra)]
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
                    rejected.pop(key,None)
                else:
                    results.pop(key,None)
                    rejected[key]=NOW.isoformat()
            except Exception as err:
                print(f"Unexpected verification error ({key}): {err}", file=sys.stderr)
    results = {key: value for key, value in results.items()
               if recent(value, MAX_AGE_DAYS) and is_macos_asset(value.get("asset_name", ""))}
    seed_categories = {key: seed["category"] for key, seed in seeds.items()}
    for entry in results.values():
        category = seed_categories.get(entry["repo"].casefold())
        if category:
            entry["category"] = category
        entry["genre"] = game_genre(entry["repo"], entry["category"], entry.get("summary") or "")
        entry["editorial_rank"] = FEATURED_REPOS.get(entry["repo"].casefold(),0)
        entry["audience"] = classify_audience(entry, entry.get("category", ""),
                                              entry.get("asset_name", ""))
        entry.setdefault("asset_names", [entry.get("asset_name", "")])
    # GitHub may redirect legacy seed names to a canonical owner/repository.
    # Deduplicate by the *returned canonical repository*, not the input key.
    canonical = {}
    for item in results.values():
        key = item["repo"].casefold()
        old = canonical.get(key)
        if old is None or (item.get("verified_at",""),item.get("stars",0)) > (
                old.get("verified_at",""),old.get("stars",0)):
            canonical[key] = item
    # Enrich icons in the scheduled index rather than firing hundreds of
    # GitHub API requests from user Macs. Reuse known paths (including misses).
    scans = 0
    seeded_first = sorted(canonical.values(), key=lambda e:(
        e["repo"].casefold() not in seeds, -int(e.get("editorial_rank") or 0)))
    for item in seeded_first:
        old = previous.get(item["repo"].casefold(), {})
        item["icon_url"] = item.get("icon_url") or old.get("icon_url")
        item["icon_checked_at"] = item.get("icon_checked_at") or old.get("icon_checked_at")
        # Only curated and high-value projects consume the bounded scan budget.
        if item["repo"].casefold() not in seeds and int(item.get("editorial_rank") or 0) < 90:
            continue
        stamp = item.get("icon_checked_at")
        if stamp and is_recent_rejection(stamp, days=ICON_RECHECK_DAYS):
            continue
        if scans >= MAX_ICON_SCANS:
            continue
        scans += 1
        try:
            url = discover_icon_url(item)
            if url:
                item["icon_url"] = url
            item["icon_checked_at"] = NOW.isoformat()
        except Exception as err:
            print(f"Icon scan skipped ({item['repo']}): {err}", file=sys.stderr)
    print(f"Icon paths reused or inspected; new tree lookups <= {MAX_ICON_SCANS}")
    # Favor curated consumer-friendly apps while separating engines from games.
    ordered_entries = sorted(canonical.values(),
                             key=lambda e:(-int(e.get("editorial_rank") or 0),
                                           -int(e.get("downloads") or 0),
                                           -int(e.get("stars") or 0),
                                           e["repo"].casefold()))[:MAX_ENTRIES]
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
    # A bounded, time-limited negative cache avoids repeatedly checking
    # popular source-only repositories; never retain individual rejections
    # beyond three weeks.
    rejected={key:timestamp for key,timestamp in rejected.items()
              if is_recent_rejection(timestamp,days=21)}
    rejected=dict(list(sorted(rejected.items(),key=lambda kv:kv[1],reverse=True))[:4000])
    REJECTED.write_text(json.dumps({"schema":VERSION,"generated_at":NOW.isoformat(),
                                    "entries":rejected},separators=(",",":"))+"\n",
                        encoding="utf-8")
    print(f"Verified {len(ordered_entries)} macOS release entries into {OUTPUT}")
    for category, count in sorted(document["categories"].items()):
        print(f"  {category}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
