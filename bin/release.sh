#!/usr/bin/env bash
#
# Release helper for the SourceCode-maintained Activity Log fork.
#
# It bumps the version in the right places, adds a changelog entry, commits,
# pushes, and creates the matching GitHub release so the live site is offered
# the update. Run it AFTER you've made (and saved) your code changes.
#
# Usage:
#   bin/release.sh <new-version> "<changelog line>" ["<another line>" ...]
#
# Example:
#   bin/release.sh 2.11.4-sc "Fix: avoid notice on empty IP" "Tweak: faster query"
#
# Requires: git, php, gh (GitHub CLI, already logged in).

set -euo pipefail

# --- locate repo root (script lives in bin/) -------------------------------
cd "$(dirname "$0")/.."

MAIN="aryo-activity-log.php"
README="readme.txt"

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
	echo "Usage: bin/release.sh <new-version> \"<changelog line>\" [more lines...]"
	echo "Example: bin/release.sh 2.11.4-sc \"Fix: ...\""
	exit 1
fi
shift
NOTES=("$@")
TAG="v${VERSION}"

# --- safety checks ---------------------------------------------------------
command -v gh  >/dev/null || { echo "ERROR: gh (GitHub CLI) not found."; exit 1; }
[[ -f "$MAIN" && -f "$README" ]] || { echo "ERROR: run this from the plugin repo (missing $MAIN / $README)."; exit 1; }
if git rev-parse "$TAG" >/dev/null 2>&1; then
	echo "ERROR: tag $TAG already exists. Pick a higher version."; exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
DATE="$(date +%Y-%m-%d)"

# --- 1. bump version in the plugin header + readme stable tag --------------
sed -i -E "s/^(Version:[[:space:]]*).*/\1${VERSION}/" "$MAIN"
sed -i -E "s/^(Stable tag:[[:space:]]*).*/\1${VERSION}/" "$README"

# --- 2. insert a changelog entry as the newest item -----------------------
tmp_entry="$(mktemp)"
{
	printf '= %s - %s =\n' "$VERSION" "$DATE"
	if [[ ${#NOTES[@]} -eq 0 ]]; then
		printf '* Maintenance release.\n'
	else
		for n in "${NOTES[@]}"; do printf '* %s\n' "$n"; done
	fi
	printf '\n'
} > "$tmp_entry"

# Insert just before the first existing version heading (= 1.2.3 ...).
# FAQ headings like "= What is ... =" start with a letter, so they're skipped.
awk 'NR==FNR { entry = entry $0 ORS; next }
     !ins && /^= [0-9]/ { printf "%s", entry; ins = 1 }
     { print }' "$tmp_entry" "$README" > "$README.new" && mv "$README.new" "$README"
rm -f "$tmp_entry"

# --- 3. lint + show the diff, then confirm --------------------------------
php -l "$MAIN" >/dev/null
echo
echo "Release ${TAG} (branch: ${BRANCH})"
echo "-----------------------------------"
git --no-pager diff --stat
echo
read -rp "Commit, push, and create the GitHub release? [y/N] " ans
[[ "${ans:-}" =~ ^[Yy]$ ]] || { echo "Aborted. Version/changelog were edited but NOT committed (run 'git checkout .' to undo)."; exit 1; }

# --- 4. commit, push, release ---------------------------------------------
SUMMARY="${NOTES[*]:-maintenance release}"
git add -A
git commit -m "${VERSION}: ${SUMMARY}"
git push origin "$BRANCH"

notes_body="$(printf '%s\n' "${NOTES[@]:-Maintenance release.}" | sed 's/^/- /')"
gh release create "$TAG" --target "$BRANCH" --title "$TAG" --notes "$notes_body"

echo
echo "✅ Released $TAG"
echo "   The live site will offer the update within ~12h (or force it now:"
echo "   WP Admin → Dashboard → Updates → Check again)."
