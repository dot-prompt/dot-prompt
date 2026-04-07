#!/bin/bash
set -euo pipefail

# ============================================================================
# TypeScript Package Publish Script
# Builds and publishes @dotprompt/client to npm
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR/../../clients/typescript"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Default: patch bump
BUMP_TYPE="patch"

# Parse arguments
DRY_RUN=false
NPM_TOKEN=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --major)
      BUMP_TYPE="major"
      shift
      ;;
    --minor)
      BUMP_TYPE="minor"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --token)
      NPM_TOKEN="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "Publishing TypeScript package (@dotprompt/client)..."

cd "$CLIENT_DIR"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Handle versioning
if [ -f "$VERSION_FILE" ]; then
    CURRENT_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
    if [[ "$CURRENT_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        
        # Parse and bump version
        MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
        MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
        PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
        
        case "$BUMP_TYPE" in
            major)
                MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0
                ;;
            minor)
                MINOR=$((MINOR + 1)); PATCH=0
                ;;
            patch)
                PATCH=$((PATCH + 1))
                ;;
        esac
        
        NEW_VERSION="$MAJOR.$MINOR.$PATCH"
        
        # Update package.json
        npm version "$NEW_VERSION" --no-git-tag-version --allow-same-version 2>/dev/null || \
            sed -i "s/\"version\": \".*\"/\"version\": \"$NEW_VERSION\"/" package.json
        
        echo "Version: $CURRENT_VERSION → $NEW_VERSION"
    fi
fi

# Build
echo "Building package..."
npm run build

# Publish
echo ""
echo "Publishing to npm..."

if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] npm publish --dry-run"
elif [ -n "$NPM_TOKEN" ]; then
    echo "$NPM_TOKEN" | npm login --registry=https://registry.npmjs.org/
    npm publish
else
    npm publish
fi

echo ""
echo "========================================"
echo "✓ Published @dotprompt/client to npm"
echo "========================================"