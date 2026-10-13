extends Control
## Things drawn over the room photo: purchased items (photo, pocket mirror).

const PHOTO_RECT := Rect2(84, 248, 22, 28)
const MIRROR_RECT := Rect2(586, 40, 46, 36)

var power_on := true
var vent_state: Dictionary = {}


func _draw() -> void:
	if GameState.owned.has("photo"):
		var r := PHOTO_RECT
		draw_rect(r, Color(0.62, 0.6, 0.55))
		draw_rect(r.grow(-2.5), Color(0.2, 0.21, 0.22))
		draw_circle(r.get_center() + Vector2(-3, -2), 3, Color(0.45, 0.4, 0.36))
		draw_circle(r.get_center() + Vector2(4, -1), 3, Color(0.45, 0.4, 0.36))
		draw_rect(Rect2(r.position.x + 6, r.position.y - 2, 11, 4), Color(0.75, 0.72, 0.62, 0.55))
	if GameState.owned.has("mirror"):
		_draw_mirror()


func _draw_mirror() -> void:
	var r := MIRROR_RECT
	draw_rect(r.grow(2), Color(0.22, 0.21, 0.19))
	draw_rect(r, Color(0.06, 0.06, 0.055) if power_on else Color(0.01, 0.01, 0.01))
	if not power_on:
		return
	var g := Rect2(r.position + Vector2(9, 7), Vector2(28, 20))
	draw_rect(g, Color(0.24, 0.23, 0.21), false, 1.0)
	var y := g.position.y + 3
	while y < g.end.y - 1:
		draw_line(Vector2(g.position.x + 1, y), Vector2(g.end.x - 1, y), Color(0.17, 0.165, 0.15))
		y += 3
	if vent_state.get("glint", false):
		draw_rect(Rect2(g.get_center() + Vector2(-4, -1), Vector2(1, 1)), Color(0.95, 0.92, 0.85))
		draw_rect(Rect2(g.get_center() + Vector2(3, -1), Vector2(1, 1)), Color(0.95, 0.92, 0.85))
	draw_rect(r, Color(0.6, 0.58, 0.5, 0.06))
