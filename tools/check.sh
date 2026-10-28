#!/usr/bin/env bash
# Every check that must pass before a commit and on CI: import, unit tests, boot with screenshots.
# Needs `godot` on the PATH (tools/ci/install_godot.sh); the boot step needs xvfb and a Vulkan driver
# (mesa-vulkan-drivers gives a software one).
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT="${CHECK_OUT:-/tmp/dont-ask-again-check}"
mkdir -p "$OUT"
rm -rf "$OUT/shots"

# Godot keeps running after script errors, so the logs decide.
fail_on_errors() {
	if grep -n -E "SCRIPT ERROR|Parse Error|ERROR:" "$1"; then
		echo "FAILED: errors in $1"
		exit 1
	fi
}

echo "== import"
"$GODOT" --headless --path . --import >"$OUT/import.log" 2>&1 || { cat "$OUT/import.log"; exit 1; }
fail_on_errors "$OUT/import.log"

echo "== unit tests"
status=0
"$GODOT" --headless --path . --script res://tests/run_tests.gd >"$OUT/tests.log" 2>&1 || status=$?
grep -E "^(PASS|FAIL|TESTS)" "$OUT/tests.log" || true
fail_on_errors "$OUT/tests.log"
[[ $status -eq 0 ]] || { echo "FAILED: unit tests"; exit 1; }

echo "== boot (Forward+ on a virtual display)"
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --audio-driver Dummy --rendering-driver vulkan \
	-- --windowed --shots="$OUT/shots" >"$OUT/boot.log" 2>&1 || { cat "$OUT/boot.log"; exit 1; }
fail_on_errors "$OUT/boot.log"
grep -q "Forward+" "$OUT/boot.log" || { echo "FAILED: not running on Forward+"; cat "$OUT/boot.log"; exit 1; }
[[ -f "$OUT/shots/boot.png" ]] || { echo "FAILED: no boot screenshot"; exit 1; }

echo "ALL CHECKS PASSED (logs and screenshots in $OUT)"
