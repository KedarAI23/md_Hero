#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIGURATION="${1:-release}"
VERSION="${2:-2.0.0-beta.1}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

swift build -c "$CONFIGURATION"

BINARY=".build/$CONFIGURATION/Pare"
APP="build/md_Hero.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BINARY" "$APP/Contents/MacOS/md_Hero"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>md_Hero</string>
    <key>CFBundleDisplayName</key>
    <string>md_Hero</string>
    <key>CFBundleIdentifier</key>
    <string>com.mdhero.app</string>
    <key>CFBundleVersion</key>
    <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>md_Hero</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
PLIST

# Ad-hoc signing is sufficient for a local beta install; this is not Developer ID notarisation.
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict "$APP"

echo "Built and verified $APP ($VERSION, build $BUILD_NUMBER)"
