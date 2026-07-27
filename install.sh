#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/grinchenkoedu/antigravity-skills.git"
CLONE_DIR="/tmp/antigravity-skills-tmp"
TARGET_DIR="$HOME/.gemini/skills"

# Directory names used before the gku- prefix was introduced. Removed on install so a
# renamed skill does not linger beside its replacement and load twice.
LEGACY_NAMES="review plan implement pr-review pr-resolve verify reference"

echo "Fetching latest skills from $REPO_URL..."

# Clean up any previous temp directory
rm -rf "$CLONE_DIR"

# Clone the repo silently
git clone --quiet --depth 1 "$REPO_URL" "$CLONE_DIR"

echo "Installing skills to $TARGET_DIR..."

mkdir -p "$TARGET_DIR"

# Remove earlier, unprefixed copies of these skills — but only ones that are recognisably
# ours. A directory called "review" could easily belong to a different toolkit, and deleting
# someone else's work would be a far worse outcome than leaving a stale copy behind.
for name in $LEGACY_NAMES; do
  legacy="$TARGET_DIR/$name"
  [ -d "$legacy" ] || continue
  if grep -rqs 'repo-profile' "$legacy"; then
    echo "  removing previous unprefixed copy: $name"
    rm -rf "$legacy"
  else
    echo "  NOTE: $TARGET_DIR/$name exists but does not look like ours — leaving it alone."
    echo "        If it is a leftover from an older install, remove it by hand."
  fi
done

# Copy skills and the shared reference, overwriting existing ones
cp -R "$CLONE_DIR/skills/"* "$TARGET_DIR/"
cp -R "$CLONE_DIR/gku-reference" "$TARGET_DIR/gku-reference"

# Clean up
rm -rf "$CLONE_DIR"

echo "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
echo "They are prefixed: /gku-plan, /gku-implement, /gku-review, /gku-pr-review,"
echo "/gku-pr-resolve, /gku-verify."
