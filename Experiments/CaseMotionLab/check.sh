#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p .build/module-cache
TEST_BINARY="$(mktemp "${TMPDIR:-/tmp}/airmouse-tap-check.XXXXXX")"
trap 'rm -f "$TEST_BINARY"' EXIT
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" swiftc -parse-as-library \
  Vendor/AirPointer/ClosedCaseTapCore.swift Experiments/CaseMotionLab/Checks/ReferenceTapChecks.swift -o "$TEST_BINARY"
"$TEST_BINARY"
CLANG_MODULE_CACHE_PATH="$PWD/.build/module-cache" swiftc -parse-as-library \
  Experiments/CaseMotionLab/Checks/OrientationChecks.swift -framework JavaScriptCore -o "$TEST_BINARY"
"$TEST_BINARY"
