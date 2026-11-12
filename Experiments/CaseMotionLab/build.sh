#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
APP="$PWD/build/CaseMotionLab.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build/module-cache
clang -fobjc-arc -Wall -Wextra -Werror -framework Foundation -framework CoreBluetooth -framework IOBluetooth \
  Vendor/AirPointer/CaseSustainedRenewal.m -o "$APP/Contents/Resources/CaseMotion.bin"
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" swiftc -swift-version 5 -parse-as-library \
  Sources/AirMouse/CaseMotionSample.swift Sources/AirMouse/CaseTapDetector.swift Sources/AirMouse/CasePointer.swift Sources/AirMouse/SystemControls.swift Sources/AirMouse/HotKey.swift Vendor/AirPointer/ClosedCaseTapCore.swift Experiments/CaseMotionLab/*.swift \
  -o "$APP/Contents/MacOS/CaseMotionLab" -framework CoreBluetooth -framework CoreAudio -framework JavaScriptCore -framework SceneKit
cp Vendor/AirPointer/Orientation.js "$APP/Contents/Resources/CaseOrientation.js"
cp Experiments/CaseMotionLab/Info.plist "$APP/Contents/Info.plist"
codesign --force --deep --sign - "$APP"
printf 'Built %s\n' "$APP"
