#!/usr/bin/env bash
# git-snag: pull one directory (recursively) from a GitHub repo, no git history.
# Usage: git-snag <dir-name> <repo-url> [branch]
set -euo pipefail

TARGET="$1"
REPO_URL="$2"
BRANCH="${3:-main}"

# Derive owner/repo from URL, strip .git
REPO_PATH=$(echo "$REPO_URL" | sed -E 's#https?://github\.com/##; s#\.git$##')

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

curl -sL "https://github.com/$REPO_PATH/tarball/$BRANCH" | tar -xz -C "$TMP"

# Find target dir, case-insensitive, shallowest match wins
MATCH=$(find "$TMP" -type d -iname "$TARGET" | awk '{print gsub(/\//,"/"), $0}' | sort -n | head -1 | cut -d' ' -f2-)

if [ -z "$MATCH" ]; then
  echo "Error: directory '$TARGET' not found in $REPO_PATH@$BRANCH" >&2
  exit 1
fi

mv "$MATCH" "./$(basename "$MATCH")"
echo "Pulled: $(basename "$MATCH")"

