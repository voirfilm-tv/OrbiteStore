#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test "$(uname -s)" = "Darwin"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' scripts/Info.plist)
swift build -c release --product OrbitStore
ROOT="$(pwd)"
APP="$ROOT/dist/staging/OrbitStore.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/.build/release/OrbitStore" "$APP/Contents/MacOS/OrbitStore"
cp "$ROOT/scripts/Info.plist" "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/OrbitStore"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP"
ln -sfn /Applications "$ROOT/dist/staging/Applications"
hdiutil create -volname OrbitStore -srcfolder "$ROOT/dist/staging" \
  -format UDZO -ov "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"
hdiutil verify "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"
shasum -a 256 "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg" > "$ROOT/dist/SHA256SUMS.txt"
echo "DMG READY: $ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"
