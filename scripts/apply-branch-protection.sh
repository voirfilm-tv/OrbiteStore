#!/usr/bin/env bash
set -euo pipefail
# Apply the repository's ruleset as a GitHub user with repository Administration: write.
# Requires: GitHub CLI (gh), authenticated as an owner/admin with permission.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="voirfilm-tv/OrbiteStore"
CONFIG="$ROOT/.github/rulesets/protect-main.json"
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required. Install from https://cli.github.com/" >&2
  exit 1
fi
if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "Log in first with: gh auth login" >&2
  exit 1
fi
EXISTING_ID="$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.name == "OrbitStore — protect main") | .id' | head -n 1)"
if [[ -n "$EXISTING_ID" ]]; then
  echo "Updating existing ruleset #$EXISTING_ID"
  gh api --method PUT "repos/$REPO/rulesets/$EXISTING_ID" --input "$CONFIG" >/dev/null
else
  echo "Creating main branch ruleset"
  gh api --method POST "repos/$REPO/rulesets" --input "$CONFIG" >/dev/null
fi
echo "Current repository rulesets:"
gh api "repos/$REPO/rulesets" --jq '.[] | {id, name, enforcement, target}'
echo "Verify the active rule in: https://github.com/$REPO/settings/rules"
