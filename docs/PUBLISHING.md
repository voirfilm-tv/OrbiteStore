# Make OrbitStore public / Publier OrbitStore

## Before changing visibility / Avant publication

1. Verify the entire Git history, workflow logs, release notes and artifacts for credentials, personal information and proprietary content. **Regex-based scans do not prove a repository is safe.**
2. Confirm the intended MIT license is present.
3. Verify README claims, real screenshots, third-party trademarks and binary distribution rights.
4. Confirm billing/usage limits for macOS GitHub Actions if the repository is still private.

## Public visibility (repository owner only)

GitHub → Settings → General → Danger Zone → Change repository visibility → Public.

This is an administrative action the currently connected GitHub integration **cannot perform**.

## Protect main (repository owner only)

Settings → Rules → Rulesets → New branch ruleset:
- Target branch: main
- Enforcement: Active
- Require a Pull Request and at least **one approval**.
- Require status check from the **OrbitStore CI / build** job (after at least one successful run).
- Prevent force-push and branch deletion; require discussion resolution.
- Avoid unnecessary admin bypasses.

On GitHub Free, rulesets for public repositories are supported. **CODEOWNERS is not a substitute for an active ruleset.**

## Community management

Enable Issues and optionally Discussions. Consider labels: good first issue, help wanted, bug, enhancement, documentation, security, ecosystem. Review every untrusted contribution.

## Build and release

Pull Requests run Swift build CI only. Production/pre-release DMG publishing is a **separate** workflow triggered by a tag or a maintainer action. The current DMG is signed ad hoc and **not** Apple-notarized; do not advise users to disable Gatekeeper.
