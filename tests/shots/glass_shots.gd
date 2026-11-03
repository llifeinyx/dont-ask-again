extends Node
## Screenshots of the front frame with ND-OS on the glass, for tests/compare_shots.gd:
##   godot --path . res://tests/shots/glass_shots.tscn -- --shots=<dir>
## ND-OS shows the mockup state (NdosMockup); the lamp stands still.

## Frames to let the renderer settle before a screenshot; the picture passes through several viewports.
const SETTLE_FRAMES: int = 5

@onready var _shot: SubViewport = $Shot
@onready var _view: FrontView = $Shot/FrontView
@onready var _lighting: FrontLighting = $Shot/FrontView/Front/Lighting


func _ready() -> void:
	var options := LaunchOptions.current()
	if options.shots_dir.is_empty():
		push_error("Give a folder: -- --shots=<dir>")
		get_tree().quit(1)
		return
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	_shot.size = manifest.view_size
	_lighting.process_mode = Node.PROCESS_MODE_DISABLED
	NdosMockup.apply(_view.desktop)
	DirAccess.make_dir_recursive_absolute(options.shots_dir)
	_lighting.mode = FrontLighting.Mode.NORMAL
	await _save(options.shots_dir, "glass_normal")
	_lighting.mode = FrontLighting.Mode.LAMP_OFF
	await _save(options.shots_dir, "glass_lamp_off")
	get_tree().quit()


func _save(dir: String, shot_name: String) -> void:
	for i: int in SETTLE_FRAMES:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path: String = dir.path_join(shot_name + ".png")
	var error: Error = _shot.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Could not save %s: %s" % [path, error_string(error)])
