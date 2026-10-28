extends Node
## Screenshots of the front frame in fixed light states, for tests/compare_shots.gd:
##   godot --path . res://tests/shots/front_shots.tscn -- --shots=<dir>
## Renders at the export's view size, so a shot lines up pixel for pixel with tests/reference.

## How far into the flicker to look for its darkest moment, and in what steps, in seconds.
const FLICKER_SEARCH: float = 5.0
const FLICKER_SEARCH_STEP: float = 0.01
## Frames to let the renderer settle before a screenshot.
const SETTLE_FRAMES: int = 3

@onready var _shot: SubViewport = $Shot
@onready var _lighting: FrontLighting = $Shot/Front/Lighting


func _ready() -> void:
	var options := LaunchOptions.current()
	if options.shots_dir.is_empty():
		push_error("Give a folder: -- --shots=<dir>")
		get_tree().quit(1)
		return
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	_shot.size = manifest.view_size
	# Time stands still: every state is set by hand.
	_lighting.process_mode = Node.PROCESS_MODE_DISABLED
	DirAccess.make_dir_recursive_absolute(options.shots_dir)
	_lighting.mode = FrontLighting.Mode.NORMAL
	await _save(options.shots_dir, "front_normal")
	_lighting.mode = FrontLighting.Mode.LAMP_OFF
	await _save(options.shots_dir, "front_lamp_off")
	_lighting.mode = FrontLighting.Mode.FLICKER
	_lighting.flicker_time = _darkest_time(_lighting.flicker)
	await _save(options.shots_dir, "front_flicker")
	get_tree().quit()


func _save(dir: String, shot_name: String) -> void:
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = dir.path_join(shot_name + ".png")
	var error: Error = _shot.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])


static func _darkest_time(pattern: FlickerPattern) -> float:
	var darkest: float = 0.0
	var time: float = 0.0
	while time < FLICKER_SEARCH:
		if pattern.sample(time) < pattern.sample(darkest):
			darkest = time
		time += FLICKER_SEARCH_STEP
	return darkest
