#!/usr/bin/env bash
# Downloads the pinned Godot build once into ~/.cache/godot and links it as `godot` in ~/.local/bin
# (set GODOT_BIN_DIR to link it elsewhere). Needs no sudo.
set -euo pipefail

VERSION="4.7.2-stable"
NAME="Godot_v${VERSION}_linux.x86_64"
CACHE="${GODOT_CACHE:-$HOME/.cache/godot}"
BIN_DIR="${GODOT_BIN_DIR:-$HOME/.local/bin}"

if [[ ! -x "$CACHE/$NAME" ]]; then
	mkdir -p "$CACHE"
	curl -fsSL -o "$CACHE/$NAME.zip" "https://github.com/godotengine/godot/releases/download/${VERSION}/${NAME}.zip"
	unzip -qo "$CACHE/$NAME.zip" -d "$CACHE"
	rm "$CACHE/$NAME.zip"
fi

mkdir -p "$BIN_DIR"
ln -sf "$CACHE/$NAME" "$BIN_DIR/godot"
"$BIN_DIR/godot" --version
