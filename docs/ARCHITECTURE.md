# Architecture / Architecture

OrbitStore is a Swift Package executable targeting macOS 13+. It has **no backend service** of its own as of v0.3.1.

| File | Responsibility / Rôle |
|---|---|
| Sources/OrbitStore/OrbitStoreApp.swift | SwiftUI UI, navigation and dialogs |
| Sources/OrbitStore/StoreModel.swift | Catalog, installed macOS apps, GitHub releases, downloads, notifications |
| Sources/OrbitStore/MarketplaceDiscovery.swift | GitHub search, ecosystem adapters, logo retrieval |
| Sources/OrbitStore/OrbitOperations.swift | Installer safety gates, queue, receipts, rollback, history, diagnostics, uninstall, source adapters |
| Sources/OrbitStore/OrbitOperationsViews.swift | Native operation views, settings, OrbitDoctor, packs |
| Sources/OrbitStore/OrbitCatalogDetails.swift | Premium editorial app-detail sheet |
| Sources/OrbitStore/OrbitPluginInstaller.swift | Official Obsidian registry plugin adapter, version checks and selected-vault installation |
| Tests/OrbitStoreTests/OrbitVersionTests.swift | Unit tests for version and archive policies |
| Package.swift | Swift package and platform version |
| scripts/Info.plist | macOS app metadata and version |
| scripts/build-dmg.sh | Ad-hoc signed app bundle and unnotarized DMG |

### Network requests / Requêtes

GitHub REST API: search, repository metadata and releases. Raw GitHub content: README and project images; Obsidian public plugin registry. Jellyfin official server plugin manifest. Project websites: icon lookup when available. These sources have different trust and rate-limit properties.

### Local data / Données locales

OrbitStore scans selected Applications directories and gathers app name, bundle ID, version and path. It stores settings and some network cache in UserDefaults. Package downloads go into ~/Downloads/OrbitStore. It rescans while running; there is no always-on privileged service.

### Architectural boundaries / Séparation future

A secure installer would need: discovery → verified identity → macOS/architecture compatibility → trusted download → integrity/signature check → explicit consent → install/update → recovery.

Never equate a GitHub search match with confirmed plugin compatibility or binary safety. Keep API usage bounded, status messages accurate, and the interface accessible.

### Discovery and download UX v0.2.2

Known application bundle IDs are prioritized over mutable display names. OrbitStore recognizes `fr.orbitstore.mac` for `voirfilm-tv/OrbiteStore`. The app inventory includes LaunchServices registrations and running macOS application bundles while excluding mounted DMG volumes. A user-requested DMG download can open the disk image through NSWorkspace; it does not install the app or bypass Gatekeeper. The user must drag the app into Applications and can rescan from the catalog detail.

### Install pipeline in v0.3.0

1. User explicitly requests a package or enables signed managed updates.
2. Resolve GitHub release and download an identified macOS package; compare SHA-256 if GitHub provides an asset digest.
3. Mount the DMG read-only using `hdiutil`, or validate ZIP paths and unpack using `ditto`.
4. Require a unique .app bundle and a valid bundle ID. Check signature and Gatekeeper assessment. Restricted/unsigned/PKG/ambiguous cases become manual.
5. Copy into /Applications or a user-chosen allowed writable directory. Replacing a previous bundle requires the same bundle ID and Team ID; keep a backup and attempt recovery on failure.
6. Persist installation receipt and local event. Managed automatic updates are opt-in and limited to recognized installed receipts.

No privileged service is bundled. Because OrbitStore itself is ad-hoc signed and not notarized, it does **not** pass its own Gatekeeper-based unattended installer.

### Plugin host adapters

Obsidian official registry provides the first implementation. It checks GitHub release asset names, manifest plugin ID and minimum Obsidian version, requests a vault directory and explicit consent, then writes plugin assets. Plugin execution requires enabling the plugin in Obsidian. Other ecosystems currently have browse-only catalogs.

### Automated catalog index — v0.3.1

See [catalog design](CATALOG.md). The GitHub Actions catalog-index workflow runs a bounded Python indexer every day, validates that GitHub releases publish macOS-named assets, deduplicates repositories and publishes a compact static JSON file in data/catalog-index.json. SwiftUI loads and caches that index locally, merging it with the starter curated catalog. Categories and the Games/Launchers split use classified release metadata; live repository search remains a separate, paginated, untrusted discovery view. An asset filename is not an authorization for automatic installation.
