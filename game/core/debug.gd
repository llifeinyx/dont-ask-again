extends CanvasLayer
## Debug overlay (F3): frames per second and frame time. Does nothing in release builds; it stays in the
## tree there so the Debug autoload is always a valid node.

var _label: Label


func _ready() -> void:
	if not OS.is_debug_build():
		process_mode = Node.PROCESS_MODE_DISABLED
		return
	layer = 128
	visible = false
	_label = Label.new()
	_label.position = Vector2(16, 16)
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_label.add_theme_constant_override("outline_size", 6)
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_overlay"):
		visible = not visible
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not visible:
		return
	var fps: float = Engine.get_frames_per_second()
	_label.text = "%d fps  %.1f ms" % [fps, 1000.0 / maxf(fps, 1.0)]
