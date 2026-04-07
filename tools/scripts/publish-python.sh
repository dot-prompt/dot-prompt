#!/bin/bash
set -euo pipefail

# ============================================================================
# Python Package Publish Script
# Builds and publishes dotprompt-client to PyPI
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR/../../clients/python"
DIST_DIR="$CLIENT_DIR/dist"
VERSION_FILE="$SCRIPT_DIR/VERSION"

# Use virtual environment if it exists
if [ -f "$CLIENT_DIR/.venv/bin/pip" ]; then
    PIP_CMD="$CLIENT_DIR/.venv/bin/pip"
    PYTHON_CMD="$CLIENT_DIR/.venv/bin/python"
    TWINE_CMD="$CLIENT_DIR/.venv/bin/twine"
else
    PYTHON_CMD="python3"
    if command -v python &> /dev/null; then
        PYTHON_CMD="python"
    fi
    PIP_CMD="$PYTHON_CMD -m pip --break-system-packages"
    TWINE_CMD="twine"
fi

# Default: patch bump
BUMP_TYPE="patch"

# Parse arguments
DRY_RUN=false
PYPI_TOKEN=""

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
      PYPI_TOKEN="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "Publishing Python package (dotprompt-client)..."

# Install dependencies
echo "Ensuring build tools are installed..."
$PIP_CMD install build twine --quiet 2>/dev/null || $PIP_CMD install build twine

# Clean previous builds
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

cd "$CLIENT_DIR"

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
        
        # Update pyproject.toml
        sed -i "s/version = \".*\"/version = \"$NEW_VERSION\"/" pyproject.toml
        
        echo "Version: $CURRENT_VERSION → $NEW_VERSION"
    fi
fi

# Build
echo "Building package..."
$PYTHON_CMD -m build

# Publish
echo ""
echo "Publishing to PyPI..."

if [ "$DRY_RUN" = true ]; then
    echo "  [DRY-RUN] $TWINE_CMD check dist/*"
    echo "  [DRY-RUN] $TWINE_CMD upload dist/*"
elif [ -n "$PYPI_TOKEN" ]; then
    $TWINE_CMD upload dist/* --token "$PYPI_TOKEN"
else
    $TWINE_CMD upload dist/*
fi

echo ""
echo "========================================"
echo "✓ Published dotprompt-client to PyPI"
echo "========================================"