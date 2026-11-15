# Roadmap / Feuille de route

OrbitStore is in **alpha**. Only checked items below are implemented.

## Available in v0.2.0 / Livré
- [x] Native SwiftUI storefront and macOS categories, including **Games / Jeux**
- [x] Live GitHub search with in-app results and GitHub stars
- [x] Installed-application discovery including proprietary apps, running apps and LaunchServices lookup for OrbitStore
- [x] Category, GitHub search, installed, ecosystem, extension and update filters
- [x] Guided DMG handoff (opens Finder disk image after explicit download, no silent install)
- [x] Extension browsing for Obsidian/Jellyfin plus GitHub-associated plugins for other ecosystems
- [x] Best-effort authentic icons with neutral fallback
- [x] GitHub release checks and downloads, SHA-256 when provided
- [x] Ad-hoc signed, non-notarized DMG build

## P0 — Stability, trust and compatibility / Fiabilité
- [ ] Test search and network failures on real macOS devices
- [ ] Verify bundle identity, app signatures and release provenance
- [ ] Define accurate compatibility for OBS, Jellyfin, Obsidian plugins
- [ ] Add unit tests and repository-specific fixture tests
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
- [ ] Installer supporting selected packages with explicit user consent
- [ ] Verify code signature and notarization status when applicable
- [ ] Update only verified, safely identified packages
- [ ] Recovery/rollback and compatibility safeguards
- [ ] Plugin installation through each host's official supported mechanism

## P3 — Community / Communauté
- [ ] Ecosystem adapter framework with tests
- [ ] Curated collections and developer submissions
- [ ] Reproducible releases and migration from manual download to updates

**Help wanted:** see [GitHub Issues](https://github.com/voirfilm-tv/OrbiteStore/issues). / Contributions bienvenues sur les Issues.
