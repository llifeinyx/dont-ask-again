extends Node
## Screenshots of the ND-OS desktop in fixed states, for tests/compare_shots.gd:
##   godot --path . res://tests/shots/ndos_shots.tscn -- --shots=<dir>
## Renders at the Figma frame size, so ndos_idle lines up pixel for pixel with the Figma export in
## tests/reference. Every shot shows the mockup's state: ObServer active, badges 3, "!" and 6.

## Frames to let the renderer settle before a screenshot.
const SETTLE_FRAMES: int = 3
## The mockup's clock: "10/17  9:00 AM".
const MOCKUP_MONTH: int = 10
const MOCKUP_DAY: int = 17
const MOCKUP_HOUR: int = 9
const MOCKUP_CORPS_REQUESTS: int = 3
const MOCKUP_HUMANET_MESSAGES: int = 6

@onready var _shot: SubViewport = $Shot
@onready var _desktop: NdosDesktop = $Shot/Desktop


func _ready() -> void:
	var options := LaunchOptions.current()
	if options.shots_dir.is_empty():
		push_error("Give a folder: -- --shots=<dir>")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(options.shots_dir)
	_show_mockup_state()
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


func _show_mockup_state() -> void:
	var clock := ClockSettings.new()
	clock.start_month = MOCKUP_MONTH
	clock.start_day = MOCKUP_DAY
	clock.start_hour = MOCKUP_HOUR
	# Time stands still.
	_desktop.clock.process_mode = Node.PROCESS_MODE_DISABLED
	_desktop.clock.settings = clock
	_desktop.clock.elapsed = 0.0
	_desktop.select(NdosDesktop.Program.OBSERVER)
	_desktop.set_badge(NdosDesktop.Program.CORPS, MOCKUP_CORPS_REQUESTS)
	_desktop.set_alert(NdosDesktop.Program.OBSERVER, true)
	_desktop.set_badge(NdosDesktop.Program.HUMANET, MOCKUP_HUMANET_MESSAGES)


func _save(dir: String, shot_name: String) -> void:
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = dir.path_join(shot_name + ".png")
	var error: Error = _shot.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
