extends Node
## Entry point: window mode, launch flags, screenshots for tests.

## Frames to let the renderer settle before a screenshot.
const SETTLE_FRAMES: int = 5

var _options: LaunchOptions


func _ready() -> void:
	_options = LaunchOptions.current()
	for arg: String in _options.unknown:
		push_warning("Unknown launch option: %s" % arg)
	if _options.windowed:
		_enter_windowed()
	if not _options.shots_dir.is_empty():
		await _save_shots()
		get_tree().quit()
	elif _options.quit_after_frames > 0:
		await _wait_frames(_options.quit_after_frames)
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			_enter_windowed()
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()


func _enter_windowed() -> void:
	var screen: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var size: Vector2i = ScreenFit.windowed_size(screen.size)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(size)
	DisplayServer.window_set_position(screen.position + (screen.size - size) / 2)


func _save_shots() -> void:
	DirAccess.make_dir_recursive_absolute(_options.shots_dir)
	await _wait_frames(SETTLE_FRAMES)
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var path: String = _options.shots_dir.path_join("boot.png")
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])


func _wait_frames(count: int) -> void:
	for i: int in count:
		await get_tree().process_frame
