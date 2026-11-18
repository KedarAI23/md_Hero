#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/make_app.sh "${1:-release}"

STAGING="build/dmg-staging"
DMG="build/Pare-1.0.dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "build/Pare.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "Pare" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

echo "Created $DMG"
