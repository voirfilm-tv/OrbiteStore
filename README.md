# OrbitStore — macOS

Une marketplace expérimentale native macOS 13+, inspirée de l'App Store et reliée à GitHub. Le projet est développé dans un dépôt privé et distribué sans abonnement Apple Developer.

## Télécharger
[Release privée v0.1.0](https://github.com/voirfilm-tv/OrbiteStore/releases/tag/v0.1.0)

DMG généré sur un runner GitHub Actions macOS 15 Apple Silicon, signé **ad hoc et NON notarisé**. Il peut être bloqué par Gatekeeper jusqu'à ce que l'utilisateur autorise explicitement l'ouverture dans les réglages de macOS. Ne pas désactiver Gatekeeper globalement.

## Fonctionnalités de la préversion

- Interface SwiftUI : Découvrir, catégories, Installées, Écosystèmes et Mises à jour.
- Catalogue sélectionné de 17 dépôts GitHub, avec étoiles GitHub (popularité, **pas** avis clients).
- Inventaire des applications dans /Applications, ~/Applications et /System/Applications, y compris les applications propriétaires.
- Rescan toutes les 35 secondes tant qu'OrbitStore est ouvert.
- Répertoires d'extensions pour Obsidian, Jellyfin, OBS, Blender, VS Code, Firefox, Chrome, Figma et Photoshop.
- Nombre réel des plugins Obsidian demandé à son registre officiel. Notifications opt-in lors de la détection d'une nouvelle application lorsque le nombre est connu.
- Vérification des releases GitHub pour les applications reconnues ; téléchargement des paquets macOS quand une archive appropriée existe, avec SHA-256 si l'éditeur expose son digest.
- Option de téléchargement automatique des nouvelles versions reconnues. **Aucune installation ou exécution silencieuse**.
- Le téléchargement est réalisé depuis les releases GitHub vers ~/Downloads/OrbitStore.

## Limites actuelles

- Les applications absentes du petit catalogue GitHub ne bénéficient pas encore d'un moteur universel d'identification des mises à jour.
- Les liens vers les plugins n'impliquent pas une compatibilité garantie ni une installation intégrée.
- Les notifications chiffrées sont limitées aux registres pour lesquels un décompte fiable est disponible.
- Les installations de logiciels et de plugins doivent être confirmées manuellement.
- L'exécutable a été compilé et le DMG vérifié par GitHub Actions, mais aucun test d'interface sur un Mac d'utilisateur n'a été réalisé.

## Construire gratuitement

Sur macOS avec les outils Xcode installés :

\`\`\`bash
swift build -c release
bash scripts/build-dmg.sh
\`\`\`

Le workflow [Build and publish private macOS DMG](.github/workflows/build-dmg.yml) compile, vérifie et publie la release privée automatiquement après les modifications du code. Il utilise les quotas GitHub Actions, susceptibles d'être facturés si les limites du compte sont dépassées. Aucune dépense Apple Developer n'est requise.

## Sécurité

Aucun contournement de Gatekeeper ; les packages sont téléchargés sans être exécutés. La correspondance app/release peut être ambiguë : vérifier soigneusement la source et la version avant toute installation. Les étoiles GitHub ne prouvent pas la sûreté d'un paquet.

## Feuille de route

1. Vérifier l'expérience réelle sur Apple Silicon et corriger les bugs d'interface.
2. Construire un index de catalogues GitHub incrémental avec déduplication et rafraîchissement économe.
3. Normaliser l'identité des applications (bundle ID, signatures, provenance) avant toute mise à jour automatique.
4. Ajouter les versions hôtes exigées par les plugins et des indicateurs « Compatible / Incompatible / Inconnu ».
5. Ajouter la mise à jour automatique avec rollback seulement pour les paquets dont la sécurité et la provenance sont vérifiables.


## Version 0.2.0 — novembre 2026

- Recherche GitHub en temps réel (API publique ; limitation de requêtes possible), avec fiches intégrées.
- Navigation interne des extensions OBS / Blender / VS Code (dépôts GitHub communautaires, compatibilité non vérifiée), et catalogues officiels Obsidian et Jellyfin.
- Icônes réelles des applications installées et tentatives depuis le README ou le site officiel du projet ; monogramme neutre sinon.
- Nouvelles catégories dont Jeux, Graphisme, Éducation, Audio & musique, Internet, Accessibilité.
- Nouvelle installation détectée et suggestions notifiées quand les notifications sont autorisées et l'application fonctionne.
- Pas d'installation automatique d'extensions ni de notarisation Apple. Les étoiles GitHub ne sont pas des avis utilisateurs.
