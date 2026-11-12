#!/usr/bin/env bash
# Android export helper. Requires: Godot 4.3 + Android SDK + OpenJDK 17 +
# export templates installed (see docs/reports/ANDROID_BUILD_REPORT.md).
#
#   ./tools/export_android.sh debug     -> build/android/micro_world_living.apk
#   ./tools/export_android.sh release   -> build/android/micro_world_living-release.apk
set -euo pipefail

GODOT="${GODOT:-godot}"
MODE="${1:-debug}"
OUT_DIR="build/android"
mkdir -p "$OUT_DIR"

if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "Godot binary not found. Set GODOT=/path/to/godot" >&2
  exit 1
fi

"$GODOT" --headless --path . --import

if [ "$MODE" = "release" ]; then
  "$GODOT" --headless --path . --export-release "Android" "$OUT_DIR/micro_world_living-release.apk"
else
  "$GODOT" --headless --path . --export-debug "Android" "$OUT_DIR/micro_world_living.apk"
fi

ls -lh "$OUT_DIR"
