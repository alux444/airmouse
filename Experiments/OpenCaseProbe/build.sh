#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
APP="$PWD/build/OpenCaseProbe.app"
mkdir -p "$APP/Contents/MacOS" .build/module-cache
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" swiftc -parse-as-library \
  Experiments/OpenCaseProbe/OpenCaseProbe.swift -o "$APP/Contents/MacOS/OpenCaseProbe"
cp Experiments/OpenCaseProbe/Info.plist "$APP/Contents/Info.plist"
codesign --force --sign - "$APP"
printf 'Built %s\n' "$APP"
