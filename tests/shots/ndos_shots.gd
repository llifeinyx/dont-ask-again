extends Node
## Screenshots of the ND-OS desktop in fixed states, for tests/compare_shots.gd:
##   godot --path . res://tests/shots/ndos_shots.tscn -- --shots=<dir>
## Renders at the Figma frame size, so ndos_idle lines up pixel for pixel with the Figma export in
## tests/reference. Every shot shows the mockup's state (NdosMockup).

## Frames to let the renderer settle before a screenshot.
const SETTLE_FRAMES: int = 3

@onready var _shot: SubViewport = $Shot
@onready var _desktop: NdosDesktop = $Shot/Desktop


func _ready() -> void:
	var options := LaunchOptions.current()
	if options.shots_dir.is_empty():
		push_error("Give a folder: -- --shots=<dir>")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(options.shots_dir)
	NdosMockup.apply(_desktop)
	await _save(options.shots_dir, "ndos_idle")
	var corps_center: Vector2 = _desktop.slot_rect(NdosDesktop.Program.CORPS).get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = corps_center
	_shot.push_input(motion, true)
	await _save(options.shots_dir, "ndos_hover")
	var press := InputEventMouseButton.new()
	press.position = corps_center
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	_shot.push_input(press, true)
	await _save(options.shots_dir, "ndos_pressed")
	get_tree().quit()


func _save(dir: String, shot_name: String) -> void:
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = dir.path_join(shot_name + ".png")
	var error: Error = _shot.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
