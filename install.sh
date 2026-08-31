#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/grinchenkoedu/antigravity-skills.git"
CLONE_DIR="/tmp/antigravity-skills-tmp"
TARGET_DIR="$HOME/.gemini/skills"
CLI_SKILLS_DIR="$HOME/.gemini/antigravity-cli/skills"
CONFIG_SKILLS_DIR="$HOME/.gemini/config/skills"

# Directory names used before the gku- prefix was introduced. Removed on install so a
# renamed skill does not linger beside its replacement and load twice.
LEGACY_NAMES="review plan implement pr-review pr-resolve verify reference init pr fix"

# Determine source: use local repo if run from within the clone, else fetch from git
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
fi

if [ -n "$SCRIPT_DIR" ] && [ -d "$SCRIPT_DIR/skills" ] && [ -d "$SCRIPT_DIR/gku-reference" ]; then
  SRC_DIR="$SCRIPT_DIR"
  echo "Installing skills from local source ($SRC_DIR)..."
else
  echo "Fetching latest skills from $REPO_URL..."
  rm -rf "$CLONE_DIR"
  git clone --quiet --depth 1 "$REPO_URL" "$CLONE_DIR"
  SRC_DIR="$CLONE_DIR"
fi

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
cp -R "$SRC_DIR/skills/"* "$TARGET_DIR/"
rm -rf "$TARGET_DIR/gku-reference"
cp -R "$SRC_DIR/gku-reference" "$TARGET_DIR/"

# Link to Antigravity CLI and config workspace skill directories if needed
for alias_dir in "$CLI_SKILLS_DIR" "$CONFIG_SKILLS_DIR"; do
  mkdir -p "$(dirname "$alias_dir")"
  if [ -L "$alias_dir" ]; then
    rm -f "$alias_dir"
  elif [ -d "$alias_dir" ]; then
    rm -rf "$alias_dir"
  fi
  ln -s "$TARGET_DIR" "$alias_dir"
done

# Clean up temporary clone if one was made
if [ "$SRC_DIR" = "$CLONE_DIR" ]; then
  rm -rf "$CLONE_DIR"
fi

echo "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
echo "Available skills: /gku-init, /gku-plan, /gku-implement, /gku-fix, /gku-review,"
echo "/gku-pr, /gku-pr-review, /gku-pr-resolve, /gku-verify."
