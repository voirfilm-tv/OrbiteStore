# Contributing / Contribuer

Thanks for helping develop OrbitStore! / Merci de contribuer au projet.

## The workflow / Méthode

1. Check [existing Issues](https://github.com/voirfilm-tv/OrbiteStore/issues); comment before starting a large change. / Vérifiez les tickets avant de commencer.
2. Create a focused branch on your fork. / Créez une branche dédiée dans votre fork.
3. Submit a Pull Request to **main**, referencing the corresponding Issue. / Ouvrez une PR vers **main** avec l'Issue liée.
4. State what changed, why, how you tested it, and any privacy/security implications. / Décrivez le changement, les tests et les risques.
5. For UI changes, include **real** macOS screenshots, never mockups. / Utilisez des captures réelles de l'application.

## Build locally / Compiler

Requires macOS 13+, Swift 5.9+ and Xcode Command Line Tools. No paid Apple Developer membership is necessary.

~~~bash
git clone https://github.com/voirfilm-tv/OrbiteStore.git
cd OrbiteStore
swift build -c debug
swift build -c release
bash scripts/build-dmg.sh
~~~

There is no unit-test target yet; CI verifies that Swift code builds.

## Architecture

- Sources/OrbitStore/OrbitStoreApp.swift: SwiftUI screens and navigation.
- Sources/OrbitStore/StoreModel.swift: catalog, installed apps, GitHub releases, downloads, notifications.
- Sources/OrbitStore/MarketplaceDiscovery.swift: GitHub search, ecosystems and icon resolution.
- scripts/: DMG packaging and version metadata.
- docs/: architecture, privacy and authentic screenshot guide.

## Contribution rules / Règles de contribution

- Do not add tracking, secret logging, privileged installers, or Gatekeeper bypasses.
- Do not label a GitHub repository as a verified macOS app without proof.
- Never treat stars as user reviews, trust scores, or security ratings.
- Respect GitHub rate limits and avoid expensive recursive scraping.
- Verify version-specific host/plugin compatibility before displaying a compatible status.
- Prefer accessible, idiomatic native SwiftUI. Test keyboard navigation and resizing.
- Do not upload personal app lists, passwords, API keys, signing credentials or copyrighted brand images without permission.
- Contributors agree to license submitted code under the repository's [MIT license](LICENSE). Preserve third-party notices where required.

## Pull Request checklist / Checklist

- [ ] Linked Issue / Issue liée
- [ ] Focused change / Changement limité et documenté
- [ ] macOS build succeeds
- [ ] UI tested on a real Mac if UI was changed; genuine screenshots when useful
- [ ] No credential or personal data included
- [ ] Security, compatibility and privacy considered
- [ ] User-facing English/French documentation updated where relevant

Be constructive and follow the [Code of Conduct](CODE_OF_CONDUCT.md).
