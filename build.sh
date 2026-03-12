#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Ping (release)..."
swift build -c release

BUILD_DIR=".build/arm64-apple-macosx/release"
APP="Ping.app"

rm -rf "$APP"

mkdir -p "$APP/Contents/MacOS"
cp "$BUILD_DIR/Ping" "$APP/Contents/MacOS/"
cp -a "$BUILD_DIR/Ping_Ping.bundle" "$APP/"
cp -a ".app/" "$APP/"

if codesign --force --deep --sign - "$APP" 2>/dev/null; then
    echo "Codesigned $APP"
else
    echo "Note: Codesigning skipped (unsealed bundle root). App will still run locally."
fi

echo "Built $APP"
