extends RefCounted
## ND-OS palette, fonts and screen geometry (logical 640x480 units).

const W := 640.0
const H := 480.0
const X0 := 45.0                    # app area (right of the launcher, under the panel)
const Y0 := 19.0
const X1 := 640.0
const Y1 := 480.0
const LH := 11.2                    # terminal line height
const CW := 5.0                     # terminal column width; the glyphs are drawn a touch
                                    # narrower (4.52), the grid is what the mockups use
# The CRT rounds off the corners of the picture (crt.gdshader: se(s, 22)), and the top row
# of the screen is where that bites: anything that has to stay readable up there lives
# between SAFE_X and W - SAFE_X. The panel bar itself may be clipped, it is just a bar.
const SAFE_X := 18.0

# How many pixels one logical unit gets in the screen SubViewport. The CRT picture covers
# only about half the window height, so a fixed 2x texture turns into a blur on a big
# monitor; main.gd calls set_scale() at startup with what the glass actually gets.
static var K := 2.0
static var MONO_PX := 15            # terminal text, physical pixels
static var UI_PX := 14              # panel text, 7 logical
static var UI_PX_BIG := 16          # panel clock, 8 logical

# Terminal font size per scale: exactly 7.5 * K, the only sizes where DejaVu Sans Mono
# draws the same glyph advance per logical unit (4.52). Off-step sizes (K=3) round to a
# different advance and silently widen every line by a tenth, so only even scales exist.
const MONO_PX_BY_K := {2: 15, 4: 30, 6: 45}


## wanted = pixels per logical unit the glass actually gets; rounds up to a usable scale.
static func set_scale(wanted: float) -> void:
	var k := 2
	if wanted > 4.0:
		k = 6
	elif wanted > 2.0:
		k = 4
	K = float(k)
	MONO_PX = int(MONO_PX_BY_K[k])
	UI_PX = 7 * k
	UI_PX_BIG = 8 * k

# Terminal colors (approved mockups).
const TBG := Color8(13, 13, 12)
const FG := Color8(198, 196, 188)
const BRIGHT := Color8(226, 222, 210)
const DIM := Color8(112, 109, 102)
const FAINT := Color8(70, 68, 63)
const ACC := Color8(205, 172, 92)
const RED := Color8(206, 92, 74)
const RED_D := Color8(130, 60, 50)
const GREEN := Color8(150, 190, 125)
const ADD_BG := Color8(24, 34, 22)
const ADD_FG := Color8(150, 190, 125)
const DEL_BG := Color8(40, 22, 20)
const DEL_FG := Color8(200, 130, 115)
const BAR_BG := Color8(30, 29, 27)

# Bureau chrome.
const PANEL_TOP := Color8(112, 104, 90)
const PANEL_BOT := Color8(90, 83, 71)
const PANEL_TXT := Color8(232, 224, 206)
const LAUNCHER := Color8(70, 64, 54)
const CHROME_BG := Color8(230, 223, 207)
const ENVELOPE := Color8(200, 180, 120)
const EYE_ON := Color8(220, 70, 60)
const EYE_OFF := Color8(150, 140, 120)
const BADGE_BG := Color8(250, 246, 236)
const BADGE_RED := Color8(200, 50, 40)
const BADGE_LINE := Color8(110, 100, 84)
const DARK := Color8(58, 51, 40)

const MONO := preload("res://fonts/DejaVuSansMono.ttf")
const MONO_B := preload("res://fonts/DejaVuSansMono-Bold.ttf")
const UI := preload("res://fonts/Ubuntu-400.ttf")
const UI_B := preload("res://fonts/Ubuntu-700.ttf")


## Word-wraps text to a column width (monospace).
static func wrap(text: String, cols: int) -> PackedStringArray:
	var out := PackedStringArray()
	for para in text.split("\n"):
		if para.length() <= cols:
			out.append(para)
			continue
		var line := ""
		for word in para.split(" "):
			if line == "":
				line = word
			elif line.length() + 1 + word.length() <= cols:
				line += " " + word
			else:
				out.append(line)
				line = word
			while line.length() > cols:
				out.append(line.substr(0, cols))
				line = line.substr(cols)
		out.append(line)
	return out


static func clip(text: String, cols: int) -> String:
	if text.length() <= cols:
		return text
	return text.substr(0, maxi(0, cols - 3)) + "..."
