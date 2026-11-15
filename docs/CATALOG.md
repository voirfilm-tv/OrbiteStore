# OrbitStore catalog index / Index du catalogue

OrbitStore uses a **server-side generated, locally cached public index** of GitHub releases, rather than a short hand-written list.

## Pipeline

1. GitHub Actions runs the catalog workflow daily at 04:35 UTC; it can also run manually.
2. The Python indexer performs bounded searches across categories including games, launchers/emulators, graphics, audio, productivity and utilities.
3. A curated seed list is checked first but does not automatically make projects installable.
4. The indexer inspects recent GitHub Releases and includes a project only when a recognizable macOS DMG, PKG or macOS-specific ZIP asset is present.
5. Results are deduplicated by owner/repository and include category, name, summary, stars, language, license, release tag and asset filename.
6. The compact result is committed as data/catalog-index.json and fetched by the macOS app as a static GitHub raw resource. The UI caches it and shows 60 cards per page.
7. The first index (November 15, 2026) found 146 macOS release projects; daily indexing adds more and rechecks old records within a bounded API budget.

## A release asset does not prove a safe or compatible app

The index verifies only that an appropriately named GitHub release asset is present. It does NOT prove that the file contains a usable native application, works on this Mac, is safe, signed, notarized or actively maintained. The local installer applies additional macOS verification.

Projects installed through Homebrew or vendor websites without GitHub Releases can be valid macOS apps, but are not confirmed for this GitHub-release feed.

## Games / Jeux

The Games category separates playable game projects from game engines, game-porting tools, emulators and launchers when source metadata permits. The latter appear under a dedicated Launchers & Emulation category. Some games require separately owned game data; installing their engine is not the same as installing a standalone game.

Steam, Epic, GOG and closed-source commercial games without GitHub releases are outside this index. Supporting these sources would require additional metadata, authentication and distribution integrations, rather than presenting source-code repositories as playable games.

## Performance, limits and privacy

The client loads one bounded static JSON file, not hundreds of GitHub API calls. The index is stored under the local Application Support/OrbitStore directory and rechecked about every six hours or explicitly on demand. Offline mode retains the previously cached index; otherwise OrbitStore falls back to its starter catalog. The indexer caps search requests, release lookups, concurrency, retention and output size. It does not import Komi Store's source code or catalog.

## Development

Run local Python policy tests with:
    python3 -m unittest discover -s tests -p test_catalog_index.py -v

Run the indexer only when you intend to build a new index, ideally with a GitHub token passed in an environment variable. Never commit API credentials. 

## Consumer and Developer modes (v0.4.0)

Consumer mode is the default. It lists only consumer-classified projects with Mac release assets, checking Intel and Apple Silicon filename markers. It searches indexed applications locally, not unrelated source repositories.

Developer Mode is an opt-in setting that reveals programming tools, source-only curated repositories, technical categories and unrestricted GitHub search. It never relaxes macOS security checks.

The indexer rejects packages labeled FreeBSD, source/debug artifacts, and terminal-only builds, and retains multiple Mac asset names when available. This is still metadata screening rather than a full unpack-and-inspect certification. A DMG/PKG/ZIP filename is not proof of executable safety or macOS compatibility.

The November 15, 2026 feed included 247 projects with Mac release assets (165 consumer-labeled and 82 developer-labeled), prior to per-Mac architecture filtering.
## Discovery performance and editorial quality — v0.5.0

- Daily index generation runs on GitHub Actions; Mac clients fetch one compressed-size JSON response that they persist under Application Support, rather than probing hundreds of repositories at startup.
- The indexer rotates deeper GitHub Search result pages between days while respecting API search limits. It checks a bounded subset of releases (maximum 480 per job, six concurrent workers) and checks curated seeds first.
- A short-lived negative cache (data/catalog-rejected.json) records repository candidates with no Mac releases, so they are not rechecked every day. Items expire within 21 days and are rechecked after approximately nine days; the index cache contains at most 4,000 negatives.
- Stable release assets are preferred; known corrupt/debug/other-platform artifacts are filtered by filename and upload size. Editorial relevance and release download counts improve ranking. These are signals, not a guarantee of app safety or software quality.
- Local icon resolver caches image bytes on disk, coalesces concurrent lookup requests, limits the number of simultaneous downloads to four, and temporarily remembers missing icons.
- Automatic installed-app update checks are throttled to a small batch per app launch; manually initiated checks can inspect a larger batch without scanning every GitHub release on every screen refresh.

## Special collections

The new **Alternatives** page is an editorial directory of more than 120 scoped substitutes, with text search, categories, and source/installation filters. Only a project present in the verified macOS-release index opens an OrbitStore installation sheet. All other entries open their publisher, Steam, browser or self-hosting documentation. A similarity suggestion is not a feature-parity or safety claim.

The **Self-hosted** collection now includes personal services alongside advanced server/network software. It opens project documentation; it never misrepresents a Docker/server project as a macOS installer. Consumer Mode keeps particularly technical infrastructure tools separate.

### Editorial discoveries beyond GitHub

Every catalog category has a hand-reviewed shelf of familiar desktop apps, games, and web products. These supplement, rather than contaminate, the automated GitHub release feed. As a result, popular software distributed only on Steam, a vendor site or the Mac App Store is now discoverable even when no GitHub installer exists. The linked publisher handles purchase or installation outside OrbitStore. Search finds matching editorial entries too.

### Authentic icon indexing

The scheduled indexer scans a bounded sample of upstream Git trees for app artwork, favoring real high-resolution app icons and rejecting badges, screenshots, mobile-only icons and UI buttons. Several explicit paths, including `supertuxkart/stk-code:data/supertuxkart_512.png`, were verified directly against their publisher repositories. Icon URLs are fetched as static raw files with disk caching and a maximum of four concurrent requests. A newly verified icon URL has its own cache key to override older incorrect README imagery. This does not prove identity for every source and does not silently replace unknown branding with invented logos.
