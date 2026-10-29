class_name NdosTokens
## Colours, fonts and sizes of ND-OS, mirroring the Figma file IlHcXHo9w4TC7ITx3utRcp, page ND-OS.
## A comment in quotes names the Figma variable; values without one are raw values from the Desktop
## frame (2:59). tools/ndos/build_theme.gd turns these into assets/ndos/theme.tres.

# Figma variables, collection "ND-OS", mode "Bureau", in Figma's order.
## "panel/top"
const PANEL_TOP := Color("#70685a")
## "panel/bottom"
const PANEL_BOTTOM := Color("#5a5347")
## "panel/text"
const PANEL_TEXT := Color("#e8e0ce")
## "launcher/bg"
const LAUNCHER_BG := Color("#464036")
## "launcher/slot"
const LAUNCHER_SLOT := Color("#5a5347")
## "launcher/slot-line"
const LAUNCHER_SLOT_LINE := Color("#968c78")
## "chrome/bg"
const CHROME_BG := Color("#e6dfcf")
## "app/bg"
const APP_BG := Color("#0d0d0c")
## "accent"
const ACCENT := Color("#cdac5c")
## "eye/on": the ObServer eye while it watches (drawn into icons/eye_open.png).
const EYE_ON := Color("#dc463c")
## "eye/off"
const EYE_OFF := Color("#968c78")
## "badge/bg": the cream badge circle (drawn into icons/badge.png).
const BADGE_BG := Color("#faf6ec")
## "badge/red": ObServer's alert circle (drawn into icons/badge_alert.png).
const BADGE_RED := Color("#c83228")
## "badge/line": the badge's pixel rim.
const BADGE_LINE := Color("#6e6454")
## "dark"
const DARK := Color("#3a3328")

## The top panel's background, top to bottom, in equal hard steps; the middle steps are raw fills.
const TOP_PANEL_STEPS: Array[Color] = [
	PANEL_TOP, Color("#6d6557"), Color("#6a6255"), Color("#675f52"),
	Color("#635c4f"), Color("#60594c"), Color("#5d564a"), PANEL_BOTTOM,
]
const TOP_PANEL_HEIGHT: int = 38
const TOP_PANEL_PADDING_LEFT: int = 20
const TOP_PANEL_PADDING_RIGHT: int = 14
const TOP_PANEL_GAP: int = 16

## Pixelify Sans weights.
const WEIGHT_MEDIUM: int = 500
const WEIGHT_SEMIBOLD: int = 600
## "ND-OS" in the top panel, SemiBold.
const TITLE_SIZE: int = 16
## The clock in the top panel, Medium.
const CLOCK_SIZE: int = 17
## Numbers and "!" on launcher badges, SemiBold.
const BADGE_SIZE: int = 15

const LAUNCHER_PADDING_TOP: int = 12
const LAUNCHER_SLOT_GAP: int = 8
const SLOT_TILE_RADIUS: int = 6
## Opacity of a locked slot's tile, icon and outline together.
const LOCKED_OPACITY: float = 0.55
## The program area's border on its left and top edges, in CHROME_BG.
const APP_AREA_BORDER: int = 2

# The selector outline around the active program: Zhan chose it over Figma's white triangles on
# 2026-10-29, and Figma's Launcher Slot, state Active, now draws it as the "Selector" frame (2 px, one
# art pixel outside the tile, hard pixel corners). Hover shows the same outline as a preview.
const SLOT_HOVER_LINE := LAUNCHER_SLOT_LINE
const SLOT_HOVER_WIDTH: int = 2
const SLOT_HOVER_RADIUS: int = 8
# Proposed in-game state that is not in Figma yet; Zhan may redraw it there.
## A pressed slot's icon and badge move down by one art pixel.
const SLOT_PRESS_OFFSET: int = 2
