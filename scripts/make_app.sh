#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIGURATION="${1:-release}"
swift build -c "$CONFIGURATION"

BINARY=".build/$CONFIGURATION/Pare"
APP="build/Pare.app"

mkdir -p "$APP/Contents/MacOS"
cp "$BINARY" "$APP/Contents/MacOS/Pare"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Pare</string>
    <key>CFBundleDisplayName</key>
    <string>Pare</string>
    <key>CFBundleIdentifier</key>
    <string>com.pare.app</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>Pare</string>
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

codesign --force --sign - "$APP" 2>/dev/null || true

echo "Built $APP — run with: open build/Pare.app"
