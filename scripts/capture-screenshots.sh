#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
APP="$PWD/dist/staging/OrbitStore.app/Contents/MacOS/OrbitStore"
test -x "$APP"
mkdir -p docs/screenshots
capture() {
  local filename="$1" section="$2" query="$3"
  echo "Launching actual SwiftUI app, page: $section"
  "$APP" "--screenshot-section=$section" "--screenshot-search=$query" "${4:-}" >/tmp/orbitstore-capture.log 2>&1 &
  local pid=$!
  sleep 9
  local windowID
  if ! windowID=$(swift scripts/window-id.swift); then
    cat /tmp/orbitstore-capture.log || true
    kill "$pid" 2>/dev/null || true
    return 1
  fi
  sleep 3
  screencapture -x -l "$windowID" -t png "docs/screenshots/$filename"
  local bytes width
  bytes=$(stat -f%z "docs/screenshots/$filename")
  width=$(sips -g pixelWidth "docs/screenshots/$filename" | awk '/pixelWidth/{print $2}')
  echo "$filename: $bytes bytes, width $width"
  if [ "$bytes" -lt 25000 ] || [ "$width" -lt 700 ]; then
    echo "Invalid or empty capture. Refusing to publish as a real app screenshot."
    kill "$pid" 2>/dev/null || true
    return 1
  fi
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  sleep 2
}
capture discover.png "Découvrir" ""
capture installed.png "Installées" ""
capture details.png "Découvrir" "" "--screenshot-app=HandBrake"
capture ecosystems.png "Écosystèmes" ""
capture search.png "Découvrir" "obs"
echo "Five authentic OrbitStore window captures validated."
