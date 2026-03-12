#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Ping (release)..."
swift build -c release

# SwiftPM's generated accessor uses Bundle.main.bundleURL (the .app root) to find
# the resource bundle, but codesigning requires everything to be inside Contents/.
# Patch the accessor to use resourceURL (Contents/Resources/) and do an incremental
# rebuild so the binary looks in the right place for a proper .app bundle.
BUILD_DIR=".build/arm64-apple-macosx/release"
ACCESSOR="$BUILD_DIR/Ping.build/DerivedSources/resource_bundle_accessor.swift"
if [ -f "$ACCESSOR" ]; then
    sed -i '' 's/Bundle\.main\.bundleURL/\(Bundle.main.resourceURL ?? Bundle.main.bundleURL\)/' "$ACCESSOR"
    swift build -c release
fi

APP="Ping.app"

rm -rf "$APP"

mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
cp "$BUILD_DIR/Ping" "$APP/Contents/MacOS/"
cp -a "$BUILD_DIR/Ping_Ping.bundle" "$APP/Contents/Resources/"
cp -a ".app/" "$APP/"

if codesign --force --deep --sign - "$APP" 2>/dev/null; then
    echo "Codesigned $APP"
else
    echo "Note: Codesigning skipped (unsealed bundle root). App will still run locally."
fi

echo "Built $APP"
