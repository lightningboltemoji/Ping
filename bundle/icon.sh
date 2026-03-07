#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

SOURCE="./Ping.png"
ICONSET="Ping.iconset"
ICNS="Ping.icns"

if [ ! -f "$SOURCE" ]; then
    echo "Error: $SOURCE not found"
    exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

for size in 16 32 128 256 512; do
    sips -z $size $size "$SOURCE" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z $double $double "$SOURCE" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
cp "$SOURCE" "$ICONSET/icon_512x512@2x.png"

iconutil --convert icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"

echo "Built $ICNS"

SVG="./Bell.svg"
RESOURCES="../Sources/Ping/Resources"

if [ -f "$SVG" ]; then
    cp "$SVG" "$RESOURCES/Bell.svg"
    echo "Copied Bell.svg"
else
    echo "Warning: $SVG not found, skipping menu bar icon"
fi
