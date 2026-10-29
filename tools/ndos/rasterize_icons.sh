#!/usr/bin/env bash
# Turns the SVGs of the ND-OS Desktop frame in Figma (file IlHcXHo9w4TC7ITx3utRcp, node 2:59) into the
# PNGs under assets/ndos/icons. Figma draws the pixel art as squares on whole pixels, so the PNGs are
# exact; the SVGs themselves are not kept in the repo.
#   tools/ndos/rasterize_icons.sh <dir with the SVGs from Figma, named as in ICONS below>
# Also draws slot_dashes.png, the dashed outline of a locked launcher slot. Figma only describes it as a
# dashed 1.5 px inside stroke; the dash, gap and offset were fitted to Figma's export of the locked slot
# (node 2:41). It is white: the game tints it with NdosTokens.LAUNCHER_SLOT_LINE.
# Needs rsvg-convert (librsvg).
set -euo pipefail
cd "$(dirname "$0")/../.."

src="${1:?give the folder with the SVGs from Figma}"
out=assets/ndos/icons
mkdir -p "$out"

# Figma name -> PNG name
declare -A ICONS=(
	[corps]=corps [observer]=observer [humanet]=humanet
	[terminal]=terminal [files]=files [settings]=settings
	[pixel_circle]=badge [pixel_circle_alert]=badge_alert [pixel_padlock]=padlock
	[eye_open]=eye_open
)
for name in "${!ICONS[@]}"; do
	rsvg-convert "$src/$name.svg" -o "$out/${ICONS[$name]}.png"
done

rsvg-convert -o "$out/slot_dashes.png" <<'SVG'
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64">
  <rect x="0.75" y="0.75" width="62.5" height="62.5" rx="5.25" fill="none" stroke="#ffffff"
    stroke-width="1.5" stroke-dasharray="3.5 2.5" stroke-dashoffset="2.5"/>
</svg>
SVG
echo "wrote $(ls "$out" | wc -l) files to $out"
