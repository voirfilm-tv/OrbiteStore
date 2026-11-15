# Protecting `main` / Protéger `main`

GitHub branch rulesets are free for public repositories on GitHub Free.

The preconfigured ruleset is [protect-main.json](../.github/rulesets/protect-main.json). It requires:

- Pull Requests before merging into `main`
- **1 approving review** from someone other than the Pull Request author
- The GitHub Actions `build` check from [OrbitStore CI](../.github/workflows/ci.yml) to pass
- Up-to-date branch checks (strict mode)
- Dismissal of old approvals after reviewable pushes
- Resolution of review comments
- No force pushes; no deletion of `main`

**Important:** The connected ChatGPT GitHub integration cannot modify repository administration settings. Committing this JSON alone does **not** enable protection.

### Apply once as repository owner

On a Mac with GitHub CLI (`gh`) installed, sign in with `gh auth login`, clone the repository, and run:

```bash
bash scripts/apply-branch-protection.sh
```

Alternatively, use **Settings → Rules → Rulesets** and import the JSON in this repo if GitHub shows the import option, or create an equivalent branch ruleset manually.

### A one-maintainer warning / Attention si vous êtes seul

GitHub does not allow you to approve your own Pull Request. Because this configuration requires one approval with **no bypass**, you must have a second reviewer before you can merge your own changes. Add a trusted collaborator, or explicitly adjust the policy after considering the trade-off. **Do not enable this rule without planning your review workflow.**

### Verify protection

Visit [repository rules](https://github.com/voirfilm-tv/OrbiteStore/settings/rules) and confirm the ruleset is **Active**, targets `main`, and requires status check `build`.

If the GitHub Actions job is renamed, update the required status context accordingly.

---

Le connecteur ChatGPT ne peut pas appliquer les règles d'administration GitHub ; le fichier de configuration doit être activé par le propriétaire du dépôt. La règle actuelle exige une véritable seconde personne pour approuver vos propres PR.
