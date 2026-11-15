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
