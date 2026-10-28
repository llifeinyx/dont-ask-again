extends TestCase
## The export in assets/front is complete, full quality and consistent with its manifest.

const ROOM_LAYERS: PackedStringArray = ["lamp", "screen", "base", "world", "indicator"]


func _manifest() -> FrontManifest:
	return load(FrontFrame.MANIFEST_PATH)


func test_is_a_full_export() -> void:
	var manifest := _manifest()
	check(not manifest.preview, "assets/front holds a preview export; run the full export")
	check_eq(manifest.frame_size, Vector2i(2816, 1584), "frame size")
	check_eq(manifest.view_size, Vector2i(2560, 1440), "view size")


func test_layer_sizes_match_the_manifest() -> void:
	var manifest := _manifest()
	for layer: String in ROOM_LAYERS:
		var room: Texture2D = load("res://assets/front/%s.exr" % layer)
		check_eq(Vector2i(room.get_size()), manifest.frame_size, layer)
		var mug: Texture2D = load("res://assets/front/mug_%s.exr" % layer)
		check_eq(Vector2i(mug.get_size()), manifest.mug_rect.size, "mug " + layer)
	var alpha: Texture2D = load("res://assets/front/mug_alpha.exr")
	check_eq(Vector2i(alpha.get_size()), manifest.mug_rect.size, "mug alpha")
	var glass: Texture2D = load("res://assets/front/glass_uv.exr")
	check_eq(Vector2i(glass.get_size()), manifest.frame_size, "glass UV")


func test_mug_sits_inside_the_frame() -> void:
	var manifest := _manifest()
	check(Rect2i(Vector2i.ZERO, manifest.frame_size).encloses(manifest.mug_rect), "mug rect inside the frame")
	check(manifest.mug_rect.position % 4 == Vector2i.ZERO and manifest.mug_rect.size % 4 == Vector2i.ZERO,
		"mug rect in whole 4x4 blocks")


func test_lut_loads() -> void:
	var lut := Lut3D.load_file(FrontFrame.LUT_PATH)
	check_eq(lut.size, 65, "LUT size")
	check(lut.lo < 0.0 and lut.hi > 0.0, "log2 range around 1.0")
