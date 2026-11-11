#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
swift build -c release "$@"
APP="$(pwd)/build/AirMouse.app"
mkdir -p "$APP/Contents/MacOS"
cp .build/release/AirMouse "$APP/Contents/MacOS/AirMouse"
cp Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
printf '\nBuilt %s\n' "$APP"
