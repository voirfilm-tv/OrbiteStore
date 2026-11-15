# Privacy / Confidentialité

This documents the reviewed **v0.2.2 source**, not an independent audit.

### On-device

OrbitStore reads app bundles from /Applications, ~/Applications and /System/Applications to display names, versions, bundle IDs and paths. Local settings and limited repository caches use UserDefaults. The app periodically rescans while running.

### External requests

- Search terms and repository lookups go to the **GitHub API**.
- Project README and image files may be fetched from GitHub or official websites.
- The Obsidian and Jellyfin registries provide plugin metadata.
- Enabling extension notifications can cause queries containing the **name of a newly installed app**.
- Opening an installed application's detail page can cause a GitHub search for extensions, including for proprietary apps.
- Network providers may receive technical request metadata (e.g. IP address).

The reviewed application source does not contain a first-party analytics backend, advertising SDK or OrbitStore user account feature. These statements do not cover third-party network logging or future versions.

### Controls / Contrôles

Disable extension notifications in Preferences. Quit OrbitStore to stop periodic inventory scans. Search queries are transmitted to GitHub. No special macOS privileges should be requested for simple discovery.

**FR :** Les applications installées sont analysées localement, mais leur nom peut être envoyé à GitHub lors d'une recherche d'extensions. Les notifications sont facultatives. Quitter OrbitStore interrompt les analyses périodiques.

### Installed app discovery as of v0.2.2

In addition to standard Applications directories, OrbitStore also reads app bundle URLs from macOS running applications, its own bundle, and LaunchServices' registered OrbitStore bundle identifier. The inventory is local, but an installed app name may be submitted to GitHub when the user requests extension discovery or has enabled related notifications. OrbitStore does not require Screen Recording or Full Disk Access for these checks.

**FR :** La recherche d'applications s'étend aux logiciels actuellement ouverts et à l'identifiant macOS d'OrbitStore ; une application simplement ouverte depuis un DMG monté n'est pas considérée comme installée.
