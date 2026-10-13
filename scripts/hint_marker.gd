extends Control
## Onboarding hint outside the monitor (turn around, lever): a pulsing frame around
## a rect of the room view and a short caption above it.

const Ui := preload("res://scripts/ui.gd")
const FONT := preload("res://fonts/DejaVuSansMono.ttf")
const FONT_PX := 8

var target := Rect2()
var caption := ""
var _time := 0.0


func show_hint(r: Rect2, text: String) -> void:
	if visible and target == r and caption == text:
		return
	target = r
	caption = text
	visible = true
	queue_redraw()


func hide_hint() -> void:
	if visible:
		visible = false


func _process(delta: float) -> void:
	if visible:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 5.0)
	var c := Color(Ui.AMBER, 0.55 + 0.45 * pulse)
	draw_rect(target.grow(2.0 + pulse), c, false, 1.0)
	if caption == "":
		return
	var w := FONT.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX).x + 8.0
	var h := 12.0
	var x := clampf(target.get_center().x - w / 2.0, 2.0, size.x - w - 2.0)
	var y := target.position.y - h - 6.0
	if y < 2.0:
		y = target.end.y + 6.0
	var box := Rect2(x, y, w, h)
	draw_rect(box, Ui.BG)
	draw_rect(box, c, false, 1.0)
	draw_string(FONT, Vector2(x + 4.0, y + h / 2.0 + (FONT.get_ascent(FONT_PX) - FONT.get_descent(FONT_PX)) / 2.0),
		caption, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_PX, Ui.AMBER)
