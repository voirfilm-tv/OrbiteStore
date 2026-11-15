# Security / Sécurité

**OrbitStore v0.4.0 is alpha software.** It discovers and downloads potentially untrusted GitHub files. It must not be treated as a trusted binary registry or a security-reviewed installer.

## Vulnerability reports / Signalement

**Do not disclose exploit details or secrets in a public Issue.**

When GitHub Private Vulnerability Reporting is enabled, use **Security → Report a vulnerability**. Otherwise, open an Issue titled **"Private security contact requested"** without technical details to request a private reporting route. A dedicated private security email has not yet been configured.

**FR :** Ne publiez ni exploit ni identifiant dans une Issue. Utilisez les signalements privés GitHub si disponibles ; sinon demandez un canal privé sans donner de détails techniques.

## Known limitations / Limites

- Only selected `.app` bundles inside DMG/ZIP files may be silently copied when the user requests installation (or explicitly opts into signed-app managed updates). The installer checks `codesign --verify --deep --strict` and `spctl --assess --type execute`; a failure requires manual handling.
- PKG installers are not silently executed, administrator privileges are not bypassed and Gatekeeper is never disabled.
- The `/Applications` directory must be writable by the current user; otherwise choose `~/Applications` or an allowed custom folder.
- GitHub asset digests are verified when present, but many assets do not supply a digest.
- A successful Gatekeeper assessment does not establish that the developer's code is safe. Not all GitHub release assets expose publisher metadata, and Homebrew/Sparkle are discovery sources only.
- Same-bundle update replacement additionally checks signing Team ID; cached previous bundles are used only for limited app rollback, not user data recovery.
- A GitHub repository may be malicious or unrelated. Stars are **not** safety ratings.
- Plugins found via keyword search may be incompatible with the installed host version. The Obsidian adapter fetches JavaScript from upstream releases following explicit consent; inclusion in the official plugin registry is not a security audit. Enable plugins inside Obsidian only after evaluating their source.
- Never recommend disabling Gatekeeper for all apps.

## Supported versions

0.3.x: alpha only; no promised security support response time. Earlier pre-releases may not receive patches.

For a report, include affected version, reproduction steps and impact privately, never access tokens or personal data.

## Public catalog security scope

The scheduled catalog indexer only checks for suitably named Mac release assets, NOT executable safety, signing identity, notarization, dependency integrity, licensing or compatibility. The client must verify macOS protections when installing. Do not treat inclusion, GitHub stars, or a Mac asset filename as an endorsement. The catalog index is fetched over HTTPS and validated for basic JSON shape and repository names.

## OrbitStore self-updates (v0.4.0)

The app downloads its own DMG only from official voirfilm-tv/OrbiteStore GitHub releases, checks its SHA-256 against the GitHub release digest or checksum manifest, and opens it in Finder. A checksum sourced from the same release validates transfer integrity, not independent publisher identity. OrbitStore does not silently replace itself, disable Gatekeeper, install a privileged helper or bypass macOS authorization.

Developer Mode changes discovery visibility only. It is not a security or permission override.