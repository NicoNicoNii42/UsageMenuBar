#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-release}"
APP_NAME="UsageMenuBar"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/Applications}"

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"

BIN_DIR="$(swift build -c "$CONFIGURATION" --show-bin-path)"
APP_DIR="$ROOT_DIR/.build/${APP_NAME}.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_DIR/$APP_NAME" "$APP_DIR/Contents/MacOS/$APP_NAME"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>dev.niconiconii.UsageMenuBar</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Created $APP_DIR"

mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/${APP_NAME}.app"
cp -R "$APP_DIR" "$INSTALL_DIR/${APP_NAME}.app"

echo "Installed $INSTALL_DIR/${APP_NAME}.app"
