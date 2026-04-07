#!/bin/bash
set -euo pipefail

# ============================================================================
# TypeScript Package Build Script
# Builds the @dotprompt/client package for npm
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_DIR="$SCRIPT_DIR/../dot-prompt-ts-client"
DIST_DIR="$CLIENT_DIR/dist"

echo "Building TypeScript package (@dotprompt/client)..."

# Check dependencies
if ! command -v npm &> /dev/null; then
    echo "ERROR: npm not found" >&2
    exit 1
fi

cd "$CLIENT_DIR"

# Install dependencies if needed
if [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install
fi

# Build the package
echo "Building package..."
npm run build

echo ""
echo "========================================"
echo "✓ Build complete"
echo "========================================"
echo "Built files:"
ls -la "$DIST_DIR"
echo "========================================"