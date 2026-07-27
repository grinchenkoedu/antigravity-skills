#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/grinchenkoedu/antigravity-skills.git"
CLONE_DIR="/tmp/antigravity-skills-tmp"
TARGET_DIR="$HOME/.gemini/skills"

echo "Fetching latest skills from $REPO_URL..."

# Clean up any previous temp directory
rm -rf "$CLONE_DIR"

# Clone the repo silently
git clone --quiet --depth 1 "$REPO_URL" "$CLONE_DIR"

echo "Installing skills to $TARGET_DIR..."

# Create target directories
mkdir -p "$TARGET_DIR"

# Copy skills and reference, overwriting existing ones
cp -R "$CLONE_DIR/skills/"* "$TARGET_DIR/"
cp -R "$CLONE_DIR/reference" "$TARGET_DIR/reference"

# Clean up
rm -rf "$CLONE_DIR"

echo "Installation/Update complete! Type '/' in Google Antigravity to see the skills."
