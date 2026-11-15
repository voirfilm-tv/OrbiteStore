#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
test "$(uname -s)" = "Darwin"
VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' scripts/Info.plist)
swift build -c release --product OrbitStore
ROOT="$(pwd)"
APP="$ROOT/dist/staging/OrbitStore.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
ICON_SOURCE="$ROOT/assets/orbitstore-icon.png"
ICONSET="$ROOT/dist/staging/OrbitStore.iconset"
test -f "$ICON_SOURCE" || { echo "Missing app icon: $ICON_SOURCE" >&2; exit 1; }
mkdir -p "$ICONSET"
sips -s format png -z 16 16 "$ICON_SOURCE" --out "$ICONSET/icon_16x16.png" >/dev/null
sips -s format png -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_16x16@2x.png" >/dev/null
sips -s format png -z 32 32 "$ICON_SOURCE" --out "$ICONSET/icon_32x32.png" >/dev/null
sips -s format png -z 64 64 "$ICON_SOURCE" --out "$ICONSET/icon_32x32@2x.png" >/dev/null
sips -s format png -z 128 128 "$ICON_SOURCE" --out "$ICONSET/icon_128x128.png" >/dev/null
sips -s format png -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_128x128@2x.png" >/dev/null
sips -s format png -z 256 256 "$ICON_SOURCE" --out "$ICONSET/icon_256x256.png" >/dev/null
sips -s format png -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_256x256@2x.png" >/dev/null
sips -s format png -z 512 512 "$ICON_SOURCE" --out "$ICONSET/icon_512x512.png" >/dev/null
sips -s format png -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET/icon_512x512@2x.png" >/dev/null
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/OrbitStore.icns"
rm -rf "$ICONSET"
cp "$ROOT/.build/release/OrbitStore" "$APP/Contents/MacOS/OrbitStore"
cp "$ROOT/scripts/Info.plist" "$APP/Contents/Info.plist"
chmod +x "$APP/Contents/MacOS/OrbitStore"
codesign --force --deep --sign - "$APP"
codesign --verify --verbose=2 "$APP"
ln -sfn /Applications "$ROOT/dist/staging/Applications"
hdiutil create -volname OrbitStore -srcfolder "$ROOT/dist/staging" \
  -format UDZO -ov "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"
# diskimages-helper can briefly return EAGAIN on CI directly after creation.
# Retry only the verification operation, and still fail on persistent errors.
for attempt in 1 2 3; do
  if hdiutil verify "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"; then
    break
  fi
  if [ "$attempt" -eq 3 ]; then
    echo "DMG verification failed after three attempts" >&2
    exit 1
  fi
  sleep 3
done
shasum -a 256 "$ROOT/dist/OrbitStore-$VERSION-unsigned.dmg" > "$ROOT/dist/SHA256SUMS.txt"
echo "DMG READY: $ROOT/dist/OrbitStore-$VERSION-unsigned.dmg"
