extends TestCase
## The inverse LUT gives back every ND-OS colour through AgX Punchy: the picture on the glass keeps the
## Figma colours.

## Allowed error in 8-bit steps; the 65³ bake measured 1.4 at most on these colours.
const TOLERANCE: float = 2.0


func test_tokens_survive_agx() -> void:
	var tokens: Script = load("res://game/ndos/ndos_tokens.gd")
	var constants: Dictionary = tokens.get_script_constant_map()
	var forward := Lut3D.load_file(FrontFrame.LUT_PATH)
	var inverse := Lut3D.load_file(FrontFrame.INVERSE_LUT_PATH)
	for name: String in ["PANEL_TOP", "PANEL_BOTTOM", "PANEL_TEXT", "LAUNCHER_BG", "LAUNCHER_SLOT",
			"LAUNCHER_SLOT_LINE", "CHROME_BG", "APP_BG", "ACCENT", "EYE_ON", "EYE_OFF", "BADGE_BG", "BADGE_RED",
			"BADGE_LINE", "DARK"]:
		var color: Color = constants[name]
		var target := Vector3(color.r, color.g, color.b)
		var log_light: Vector3 = inverse.sample(target)
		var shaper: Vector3 = (log_light - Vector3.ONE * forward.lo) / (forward.hi - forward.lo)
		var shown: Vector3 = forward.sample(shaper)
		var error: float = (shown - target).abs()[(shown - target).abs().max_axis_index()] * 255.0
		check(error <= TOLERANCE, "%s is off by %.2f steps" % [name, error])
