# Roadmap / Feuille de route

OrbitStore is in **alpha**. Only checked items below are implemented.

## Available in v0.3.0 / Livré
- [x] Native SwiftUI storefront and macOS categories, including **Games / Jeux**
- [x] Live GitHub search with in-app results and GitHub stars
- [x] Installed-application discovery including proprietary apps, running apps and LaunchServices lookup for OrbitStore
- [x] Category, GitHub search, installed, ecosystem, extension and update filters
- [x] Guided DMG handoff and narrowly scoped silent installation of macOS-approved .app files in selected writable directory
- [x] Extension browsing for Obsidian/Jellyfin plus GitHub-associated plugins for other ecosystems
- [x] Best-effort authentic icons with neutral fallback
- [x] GitHub release checks and downloads, SHA-256 when provided
- [x] Ad-hoc signed, non-notarized DMG build
- [x] Local installation queue, curated packs and user multi-selection
- [x] Code-signature and Gatekeeper assessment before unattended .app copy
- [x] Limited managed updates with persisted signed application receipts
- [x] Transactional previous-bundle backup, rollback option (not user data)
- [x] OrbitDoctor diagnostics, local operation history and controlled Trash uninstall
- [x] GitHub/Homebrew/Sparkle discovery and version changelog/ignore controls
- [x] Official Obsidian registry adapter (manual vault selection, manifest validation, explicit consent)
- [x] Editorial multi-tab app detail page
- [x] Six Swift unit tests for versions, ZIP path safety and repository IDs


## P0 — Stability, trust and compatibility / Fiabilité
- [ ] Test search and network failures on real macOS devices
- [ ] Verify bundle identity, app signatures and release provenance
- [ ] Define accurate compatibility for OBS, Jellyfin, Obsidian plugins
- [x] Add initial unit tests for core version and archive policy
- [ ] Expand coverage with DMG/ZIP fixtures and simulator integration tests
- [ ] Check Apple Silicon and Intel behavior
- [ ] Validate authentic application screenshots

## P1 — Discovery and polish / Découverte et finition
- [ ] Distinguish installable macOS apps vs source-only repositories
- [ ] Cache, paginate, deduplicate and rank repository search results
- [ ] Improve official icon resolution without excessive network calls
- [ ] Sort/filter by category, freshness, license, architecture
- [ ] In-app extension details including compatible/incompatible/unknown
- [ ] Translate all UI strings into English and French

## P2 — Secure installations and updates / Installations
- [x] Basic DMG/ZIP .app installer with explicit user consent for initial installation
- [ ] Reliable PKG support through authorized native macOS mechanisms
- [ ] Verify code signature and notarization status when applicable
- [ ] Update only verified, safely identified packages
- [x] Basic bundle rollback when previous same-team signature verified
- [ ] End-to-end rollback safety under app data migrations and permission failures
- [x] Obsidian official-registry plugin adapter with manual vault choice
- [ ] OBS, Blender and Jellyfin official adapter-based installation with verified host/API compatibility

## P3 — Community / Communauté
- [ ] Ecosystem adapter framework with tests
- [ ] Curated collections and developer submissions
- [ ] Reproducible releases and migration from manual download to updates

**Help wanted:** see [GitHub Issues](https://github.com/voirfilm-tv/OrbiteStore/issues). / Contributions bienvenues sur les Issues.
