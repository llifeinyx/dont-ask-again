#!/usr/bin/env bash
# Every check that must pass before a commit and on CI: import, compile everything, unit tests,
# boot with a screenshot, screenshots of fixed states compared with Blender and with approved goldens.
# UPDATE_GOLDEN=1 replaces the goldens with the new screenshots instead of comparing.
# Needs `godot` on the PATH (tools/ci/install_godot.sh); the screenshot steps need xvfb and a Vulkan
# driver (mesa-vulkan-drivers gives a software one).
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="${GODOT:-godot}"
OUT="${CHECK_OUT:-/tmp/dont-ask-again-check}"
# Seconds before a hung Godot is killed; a script error in _init can leave it idling forever.
LIMIT="${CHECK_TIMEOUT:-300}"
mkdir -p "$OUT"
rm -rf "$OUT/shots"

# Godot keeps running after script errors, so the logs decide.
fail_on_errors() {
	if grep -n -E "SCRIPT ERROR|Parse Error|ERROR:" "$1"; then
		echo "FAILED: errors in $1"
		exit 1
	fi
}

# run <name> <command...>: runs with a time limit, logs to $OUT/<name>.log, fails on a bad exit or errors.
run() {
	local name="$1" status=0
	shift
	timeout "$LIMIT" "$@" >"$OUT/$name.log" 2>&1 || status=$?
	if [[ $status -ne 0 ]]; then
		cat "$OUT/$name.log"
		[[ $status -eq 124 ]] && echo "FAILED: $name timed out after ${LIMIT}s" || echo "FAILED: $name exited with $status"
		exit 1
	fi
	grep -E "^(PASS|FAIL|BROKEN|TESTS|COMPILE|SHOTS)" "$OUT/$name.log" || true
	fail_on_errors "$OUT/$name.log"
}

echo "== import"
# Not headless: with a rendering device Godot compresses the light layers to BC6H on the GPU in seconds;
# headless falls back to the CPU and takes over ten minutes.
run import xvfb-run -a -s "-screen 0 1280x720x24" \
	"$GODOT" --path . --audio-driver Dummy --rendering-driver vulkan --import

echo "== compile every script and scene"
run compile "$GODOT" --headless --path . --script res://tests/compile_all.gd

echo "== unit tests"
run tests "$GODOT" --headless --path . --script res://tests/run_tests.gd

echo "== boot (Forward+ on a virtual 1440p display)"
run boot xvfb-run -a -s "-screen 0 2560x1440x24" \
	"$GODOT" --path . --audio-driver Dummy --rendering-driver vulkan -- --shots="$OUT/shots"
grep -q "Forward+" "$OUT/boot.log" || { echo "FAILED: not running on Forward+"; cat "$OUT/boot.log"; exit 1; }
[[ -f "$OUT/shots/boot.png" ]] || { echo "FAILED: no boot screenshot"; exit 1; }

echo "== front screenshots"
run front_shots xvfb-run -a -s "-screen 0 1280x720x24" \
	"$GODOT" --path . --audio-driver Dummy --rendering-driver vulkan --scene res://tests/shots/front_shots.tscn \
	-- --shots="$OUT/shots/front"

echo "== compare screenshots"
run compare "$GODOT" --headless --path . --script res://tests/compare_shots.gd \
	-- --shots="$OUT/shots/front" ${UPDATE_GOLDEN:+--update-golden}

echo "ALL CHECKS PASSED (logs and screenshots in $OUT)"
