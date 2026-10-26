#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
test_work_dir="$(mktemp -d "${TMPDIR:-/tmp}/eridesafe-map-tests.XXXXXX")"
trap 'rm -rf "$test_work_dir"' EXIT

xcrun swiftc \
    -module-cache-path "$test_work_dir/module-cache" \
    "$project_root/eRideSafe/Models/DeviceClass.swift" \
    "$project_root/eRideSafe/Models/RideZone.swift" \
    "$project_root/eRideSafe/Models/SafetyMapData.swift" \
    "$project_root/scripts/map-model-tests.swift" \
    -o "$test_work_dir/map-model-tests"
"$test_work_dir/map-model-tests"
