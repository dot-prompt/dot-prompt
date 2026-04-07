#!/bin/bash
set -euo pipefail

# ============================================================================
# Python Package Build Script
# Builds the dotprompt-client package for PyPI
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR/../dot-prompt-python-client"
DIST_DIR="$CLIENT_DIR/dist"

echo "Building Python package (dotprompt-client)..."

# Check dependencies
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "ERROR: Python not found" >&2
    exit 1
fi

# Use virtual environment if it exists
if [ -f "$CLIENT_DIR/.venv/bin/pip" ]; then
    PIP_CMD="$CLIENT_DIR/.venv/bin/pip"
    PYTHON_CMD="$CLIENT_DIR/.venv/bin/python"
else
    PYTHON_CMD="python3"
    if command -v python &> /dev/null; then
        PYTHON_CMD="python"
    fi
    PIP_CMD="$PYTHON_CMD -m pip --break-system-packages"
fi

# Install build dependencies if needed
echo "Ensuring build tools are installed..."
$PIP_CMD install build --quiet 2>/dev/null || $PIP_CMD install build

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

# Build the package
echo "Building package..."
cd "$CLIENT_DIR"
$PYTHON_CMD -m build

echo ""
echo "========================================"
echo "✓ Build complete"
echo "========================================"
echo "Built packages:"
ls -la "$DIST_DIR"
echo "========================================"