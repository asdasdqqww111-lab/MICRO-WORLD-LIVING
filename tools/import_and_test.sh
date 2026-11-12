#!/usr/bin/env bash
# One-shot: import assets, then run the headless acceptance suite.
set -euo pipefail
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . tests/test_runner.tscn
echo "--- results: docs/reports/headless_test_results.txt ---"
