# Architecture / Architecture

OrbitStore is a Swift Package executable targeting macOS 13+. It has **no backend service** of its own as of v0.2.0.

| File | Responsibility / Rôle |
|---|---|
| Sources/OrbitStore/OrbitStoreApp.swift | SwiftUI UI, navigation and dialogs |
| Sources/OrbitStore/StoreModel.swift | Catalog, installed macOS apps, GitHub releases, downloads, notifications |
| Sources/OrbitStore/MarketplaceDiscovery.swift | GitHub search, ecosystem adapters, logo retrieval |
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
