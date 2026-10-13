extends Control
## The view behind the player: ventilation grate, reboot lever, tally marks.

const GRATE := Rect2(196, 56, 248, 164)
const LEVER_RECT := Rect2(486, 150, 70, 120)
const NOTE_RECT := Rect2(232, 200, 24, 14)

var state: Dictionary = {"screws_missing": 0, "dust": false, "note": false, "glint": false}
var power_on := true
var lever_progress := 0.0
var tallies := 23


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.036, 0.032))
	for i in 60:
		var x := fposmod(i * 71.7, 640.0)
		var y := fposmod(i * 37.3, 360.0)
		draw_rect(Rect2(x, y, 1 + (i % 3), 1), Color(0.045, 0.052, 0.048))

	# Grate.
	var g := GRATE
	draw_rect(g.grow(5), Color(0.1, 0.105, 0.1))
	draw_rect(g, Color(0.006, 0.008, 0.007))
	var y := g.position.y + 6
	while y < g.end.y - 6:
		draw_rect(Rect2(g.position.x + 4, y, g.size.x - 8, 5), Color(0.13, 0.14, 0.13))
		draw_line(Vector2(g.position.x + 4, y + 5), Vector2(g.end.x - 4, y + 5), Color(0.04, 0.045, 0.04))
		y += 11

	var corners := [
		g.position + Vector2(-1, -1),
		Vector2(g.end.x + 1, g.position.y - 1),
		Vector2(g.position.x - 1, g.end.y + 1),
		g.end + Vector2(1, 1),
	]
	var missing := int(state.get("screws_missing", 0))
	for i in 4:
		var p: Vector2 = corners[i]
		if i >= 4 - missing:
			draw_circle(p, 2.5, Color(0.0, 0.0, 0.0))
		else:
			draw_circle(p, 3.0, Color(0.3, 0.3, 0.28))
			draw_line(p - Vector2(2, 0), p + Vector2(2, 0), Color(0.12, 0.12, 0.1))

	if state.get("dust", false):
		for i in 16:
			draw_rect(Rect2(g.end.x - 60 + fposmod(i * 37.0, 56.0), g.end.y + 7 + (i % 3) * 2, 1, 1), Color(0.42, 0.42, 0.37))

	if state.get("note", false):
		draw_rect(NOTE_RECT, Color(0.62, 0.6, 0.52))
		draw_line(NOTE_RECT.position + Vector2(3, 5), NOTE_RECT.position + Vector2(19, 5), Color(0.3, 0.28, 0.25))
		draw_line(NOTE_RECT.position + Vector2(3, 9), NOTE_RECT.position + Vector2(14, 9), Color(0.3, 0.28, 0.25))

	if state.get("glint", false):
		var c := g.get_center() + Vector2(-8, 6)
		draw_rect(Rect2(c, Vector2(2, 1)), Color(0.85, 0.95, 0.88))
		draw_rect(Rect2(c + Vector2(14, 0), Vector2(2, 1)), Color(0.85, 0.95, 0.88))

	# Tally marks scratched into the wall.
	var tally_col := Color(0.19, 0.21, 0.19)
	for i in tallies:
		var group := int(i / 5.0)
		var k := i % 5
		var x0 := 56.0 + group * 26.0
		if k < 4:
			draw_line(Vector2(x0 + k * 4, 240), Vector2(x0 + k * 4 + 1, 262), tally_col, 1.0)
		else:
			draw_line(Vector2(x0 - 3, 258), Vector2(x0 + 15, 244), tally_col, 1.0)

	# Reboot panel and lever.
	var lr := LEVER_RECT
	draw_rect(lr, Color(0.09, 0.09, 0.085))
	draw_rect(lr, Color(0.16, 0.16, 0.15), false, 1.0)
	var font := get_theme_default_font()
	draw_string(font, Vector2(lr.position.x + 6, lr.position.y + 12), "REBOOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.62, 0.55, 0.42))
	var pivot := Vector2(lr.get_center().x, lr.end.y - 26)
	var a := lerpf(-1.35, 1.15, clampf(lever_progress, 0.0, 1.0))
	var tip := pivot + Vector2(cos(a), sin(a)) * 34.0
	draw_line(pivot, tip, Color(0.36, 0.36, 0.34), 4.0)
	draw_circle(tip, 5.0, Color(0.6, 0.15, 0.12))
	draw_circle(pivot, 4.0, Color(0.2, 0.2, 0.2))
	draw_string(font, Vector2(lr.position.x - 34, lr.end.y + 24), "POWER FAILURE ONLY. HOLD.", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.45, 0.42, 0.36))
