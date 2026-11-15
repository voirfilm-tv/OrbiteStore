# OrbitStore

**A GitHub-powered app and extension explorer for macOS.**  
**Un explorateur d'applications et d'extensions GitHub pour macOS.**

[![macOS](https://img.shields.io/badge/macOS-13%2B-24292f?logo=apple)](https://www.apple.com/macos/)
[![SwiftUI](https://img.shields.io/badge/Swift-SwiftUI-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![CI](https://github.com/voirfilm-tv/OrbiteStore/actions/workflows/ci.yml/badge.svg)](https://github.com/voirfilm-tv/OrbiteStore/actions/workflows/ci.yml)
[![MIT](https://img.shields.io/badge/license-MIT-blue)](LICENSE)
[![Alpha](https://img.shields.io/badge/status-alpha-orange)](ROADMAP.md)

[English](#english) · [Français](#français) · [Contributing](CONTRIBUTING.md) · [Roadmap](ROADMAP.md) · [Issues](https://github.com/voirfilm-tv/OrbiteStore/issues)

<!-- ORBITSTORE_SCREENSHOTS_START -->
## Screenshots / Captures d'écran

Real screenshots of the running app will appear here after verification. **No AI-generated UI mockups.** See [screenshot instructions](docs/screenshots/README.md).

Les véritables captures de l'application macOS apparaîtront ici après vérification. **Aucune maquette présentée comme une capture.**
<!-- ORBITSTORE_SCREENSHOTS_END -->

## English

### About

OrbitStore is an experimental **native SwiftUI application** for macOS 13+. It brings together a curated GitHub software catalog, live repository search, installed-app discovery, extensions and GitHub releases. This is an **early alpha (v0.2.0)**, not yet a complete package manager.

### Implemented in v0.2.0

- Native catalog: Discover, Installed, Ecosystems, Updates and expanded categories, including **Games**.
- Live GitHub repository search and GitHub star counts (**popularity, not user reviews or a security rating**).
- Installed-app inventory for common macOS Applications directories, including proprietary apps; periodic rescan while the app runs.
- In-app extension browsing: Obsidian and Jellyfin registry data, plus GitHub-based results for OBS and other ecosystems. **Compatibility is not guaranteed.**
- Real app icons for locally installed applications; best-effort repository or official-website imagery, neutral fallback otherwise.
- GitHub release checks for known apps and optional package **download**; SHA-256 is checked when GitHub supplies a digest.
- Optional extension discovery notifications for newly detected applications.

### Current limitations

- **No universal automatic installer, updater, plugin installer, or rollback.** Downloading a package does not install it.
- GitHub search can reach API limits and can return repositories without a usable macOS build.
- Third-party plugins discovered by keywords are **not necessarily compatible** with the host app or your installed version.
- Download safety checks are incomplete: signatures and notarization of third-party binaries are not universally verified.
- Distributed DMGs are **ad-hoc signed, not Apple-notarized**. macOS Gatekeeper may require explicit user action.

### Download and build

[Download the experimental v0.2.0 DMG](https://github.com/voirfilm-tv/OrbiteStore/releases/tag/v0.2.0)

Build from source on macOS 13+ with the free Xcode Command Line Tools:

~~~bash
git clone https://github.com/voirfilm-tv/OrbiteStore.git
cd OrbiteStore
swift build -c release
bash scripts/build-dmg.sh
~~~

Output: dist/OrbitStore-0.2.0-unsigned.dmg. Do **not** disable Gatekeeper globally.

### Contribute

Start with the [contributing guide](CONTRIBUTING.md), [open tasks](https://github.com/voirfilm-tv/OrbiteStore/issues), [roadmap](ROADMAP.md), [architecture](docs/ARCHITECTURE.md), [privacy](docs/PRIVACY.md), and [security reporting](SECURITY.md). Small, well-scoped Pull Requests are particularly welcome.

### License

[MIT](LICENSE) covers OrbitStore source code. Third-party app names, trademarks, logos, GitHub content and plugins belong to their respective owners. Listing them does not imply endorsement or verified compatibility.

---

## Français

### Présentation

OrbitStore est une **application native SwiftUI pour macOS 13+**, développée en open source. Elle permet de découvrir des projets GitHub, consulter des dépôts en direct, retrouver les logiciels installés sur le Mac et explorer leurs extensions.

**Version actuelle : alpha 0.2.0.** Il ne s'agit pas encore d'un gestionnaire d'installation universel.

**Déjà disponible :** catalogue et catégories dont **Jeux**, recherche GitHub réelle, nombre d'étoiles GitHub (popularité uniquement), inventaire des applications installées y compris propriétaires, consultation interne de catalogues d'extensions, icônes authentiques quand elles sont disponibles, vérification de releases et téléchargement de certains paquets.

**Ce qui reste à développer :** installation et mise à jour automatiques fiables, vérification systématique de la provenance des paquets, compatibilité précise des plugins, tests utilisateurs et couverture plus large du catalogue. Les DMG ne sont pas notarisés par Apple.

Pour compiler sans payer Apple, installez Xcode ou les Command Line Tools et utilisez les commandes ci-dessus.

**Contribuer :** [guide de contribution](CONTRIBUTING.md) · [feuille de route](ROADMAP.md) · [Issues](https://github.com/voirfilm-tv/OrbiteStore/issues) · [confidentialité](docs/PRIVACY.md) · [sécurité](SECURITY.md).

**Licence MIT.** Les logos et marques tiers conservent leurs droits respectifs.
