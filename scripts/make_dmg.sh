#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

./scripts/make_app.sh "${1:-release}"

STAGING="build/dmg-staging"
DMG="build/md_Hero-1.0.dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "build/md_Hero.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "md_Hero" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

echo "Created $DMG"
