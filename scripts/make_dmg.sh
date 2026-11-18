#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIGURATION="${1:-release}"
VERSION="${2:-2.0.0-beta.1}"
DMG_NAME="md_Hero-${VERSION}.dmg"
STAGING="build/dmg-staging"
DMG="build/$DMG_NAME"

./scripts/make_app.sh "$CONFIGURATION" "$VERSION"

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
cp -R "build/md_Hero.app" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "md_Hero $VERSION" -srcfolder "$STAGING" -ov -format UDZO "$DMG"
rm -rf "$STAGING"

hdiutil verify "$DMG"
shasum -a 256 "$DMG" > "$DMG.sha256"

echo "Created $DMG"
echo "SHA-256: $(cut -d ' ' -f 1 "$DMG.sha256")"
