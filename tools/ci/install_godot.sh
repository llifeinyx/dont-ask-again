#!/usr/bin/env bash
# Downloads the pinned Godot build once into ~/.cache/godot and links it as `godot` on the PATH.
set -euo pipefail

VERSION="4.7.2-stable"
NAME="Godot_v${VERSION}_linux.x86_64"
CACHE="${GODOT_CACHE:-$HOME/.cache/godot}"
BIN_DIR="${GODOT_BIN_DIR:-/usr/local/bin}"

if [[ ! -x "$CACHE/$NAME" ]]; then
	mkdir -p "$CACHE"
	curl -sSL -o "$CACHE/$NAME.zip" "https://github.com/godotengine/godot/releases/download/${VERSION}/${NAME}.zip"
	unzip -qo "$CACHE/$NAME.zip" -d "$CACHE"
	rm "$CACHE/$NAME.zip"
fi

if [[ -w "$BIN_DIR" ]]; then
	ln -sf "$CACHE/$NAME" "$BIN_DIR/godot"
else
	sudo ln -sf "$CACHE/$NAME" "$BIN_DIR/godot"
fi
godot --version
