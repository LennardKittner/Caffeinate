#!/bin/bash
# Assemble Caffeinate.app by compiling the sources with swiftc — no full Xcode
# required, only the Command Line Tools. (Modeled on dev-pm/scripts/make-app.sh.)
# Note: the asset-catalog app icon is not compiled here; the menu-bar item uses
# an SF Symbol, so that only affects the (hidden) Dock/Finder icon.
set -euo pipefail
cd "$(dirname "$0")/.."

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
BUILD=".build"
APP="Caffeinate.app"

mkdir -p "$BUILD"
swiftc \
    -sdk "$SDK" \
    -target "${ARCH}-apple-macosx13.0" \
    -O \
    -o "$BUILD/Caffeinate" \
    Caffeinate/CaffeinateApp.swift \
    Caffeinate/Appdelegate.swift \
    Caffeinate/Settings/ConfigData.swift \
    Caffeinate/Settings/ConfigHandler.swift

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BUILD/Caffeinate" "$APP/Contents/MacOS/Caffeinate"

# Build AppIcon.icns from the asset-catalog PNGs (Xcode would compile these via
# actool, which isn't available with the Command Line Tools alone).
ICONSRC="Caffeinate/Assets.xcassets/AppIcon.appiconset"
ICONSET="$BUILD/AppIcon.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
cp "$ICONSRC/icon_16.png"   "$ICONSET/icon_16x16.png"
cp "$ICONSRC/icon_32.png"   "$ICONSET/icon_16x16@2x.png"
cp "$ICONSRC/icon_32.png"   "$ICONSET/icon_32x32.png"
cp "$ICONSRC/icon_64.png"   "$ICONSET/icon_32x32@2x.png"
cp "$ICONSRC/icon_128.png"  "$ICONSET/icon_128x128.png"
cp "$ICONSRC/icon_256.png"  "$ICONSET/icon_128x128@2x.png"
cp "$ICONSRC/icon_256.png"  "$ICONSET/icon_256x256.png"
cp "$ICONSRC/icon_512.png"  "$ICONSET/icon_256x256@2x.png"
cp "$ICONSRC/icon_512.png"  "$ICONSET/icon_512x512.png"
cp "$ICONSRC/icon_1024.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>Caffeinate</string>
    <key>CFBundleIdentifier</key><string>com.Lennard.Caffeinate</string>
    <key>CFBundleName</key><string>Caffeinate</string>
    <key>CFBundleDisplayName</key><string>Caffeinate</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundleIconName</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.2.0</string>
    <key>CFBundleVersion</key><string>3</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Lennard Kittner</string>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" 2>/dev/null || true
echo "Built $APP"
