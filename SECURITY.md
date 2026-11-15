# Security / Sécurité

**OrbitStore v0.2.0 is alpha software.** It discovers and downloads potentially untrusted GitHub files. It must not be treated as a trusted binary registry or a security-reviewed installer.

## Vulnerability reports / Signalement

**Do not disclose exploit details or secrets in a public Issue.**

When GitHub Private Vulnerability Reporting is enabled, use **Security → Report a vulnerability**. Otherwise, open an Issue titled **"Private security contact requested"** without technical details to request a private reporting route. A dedicated private security email has not yet been configured.

**FR :** Ne publiez ni exploit ni identifiant dans une Issue. Utilisez les signalements privés GitHub si disponibles ; sinon demandez un canal privé sans donner de détails techniques.

## Known limitations / Limites

- Downloaded artifacts are **not installed or run automatically**.
- GitHub asset digests are verified when present, but many assets do not supply a digest.
- Third-party code signatures, Developer ID and Apple notarization are **not yet systematically verified**.
- A GitHub repository may be malicious or unrelated. Stars are **not** safety ratings.
- Plugins found via keyword search may be incompatible with the installed host version.
- Never recommend disabling Gatekeeper for all apps.

## Supported versions

0.2.x: alpha only; no promised security support response time. Earlier pre-releases may not receive patches.

For a report, include affected version, reproduction steps and impact privately, never access tokens or personal data.
