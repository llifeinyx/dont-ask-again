extends Control
## When the screen goes dark, the glass reflects what stands behind the player.

const EYES_AT := Vector2(306, 132)

var eyes := false


func _draw() -> void:
	if not eyes:
		return
	var c := Color(0.95, 0.92, 0.84, 0.9)
	for p in [EYES_AT, EYES_AT + Vector2(10, 0.5)]:
		draw_circle(p, 3.0, Color(0.9, 0.85, 0.7, 0.035))
		draw_rect(Rect2(p - Vector2(1, 0.75), Vector2(2, 1.5)), c)
