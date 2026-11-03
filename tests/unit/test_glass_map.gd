extends TestCase

## A frame pixel near the middle of the glass and where the UV pass puts it on the glass (measured).
const CENTER_PIXEL := Vector2(1407.5, 790.5)
const CENTER_UV := Vector2(0.4997, 0.5048)
## Grid of ND-OS points for the round trip, edges and corners included.
const GRID := Vector2i(9, 7)
## ND-OS pixels between the picture's edge and the outer points of the grid: the raster reaches under the
## bezel and its rounded corners, so the picture's own corners are hidden.
const GRID_INSET: float = 24.0


func _map() -> GlassMap:
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	var fit: GlassFit = load("res://game/glass/fit.tres")
	return GlassMap.load_default(manifest, fit)


func test_view_to_frame_adds_the_margin() -> void:
	var map := _map()
	check_eq(map.view_origin, Vector2i(128, 72), "the view sits in the middle of the frame")
	check_eq(map.view_to_frame(Vector2(10, 20)), Vector2(138, 92), "view to frame")


func test_frame_to_ndos() -> void:
	var map := _map()
	var hit: Vector3 = map.frame_to_glass(CENTER_PIXEL)
	check(Vector2(hit.x, hit.y).distance_to(CENTER_UV) < 0.001, "middle of the glass: %s" % hit)
	check(is_equal_approx(hit.z, 1.0), "fully covered")
	var ndos: Vector3 = map.frame_to_ndos(CENTER_PIXEL)
	check_eq(Vector2(ndos.x, ndos.y), map.fit.glass_to_ndos(Vector2(hit.x, hit.y)), "ND-OS follows the fit")
	check(GlassMap.on_picture(ndos), "the middle of the glass shows ND-OS")
	check_eq(map.frame_to_ndos(Vector2(100, 100)), Vector3.ZERO, "the wall is not glass")
	check_eq(map.frame_to_ndos(Vector2(-1, 5)), Vector3.ZERO, "outside the frame")
	check(not map.is_glass(Vector2(100, 100)), "is_glass agrees")


func test_round_trip_within_a_pixel() -> void:
	var map := _map()
	var ndos_size := Vector2(NdosTokens.SCREEN_SIZE)
	for y: int in GRID.y:
		for x: int in GRID.x:
			var inset: Vector2 = Vector2(GRID_INSET, GRID_INSET) / ndos_size
			var uv := Vector2(lerpf(inset.x, 1.0 - inset.x, float(x) / (GRID.x - 1)),
				lerpf(inset.y, 1.0 - inset.y, float(y) / (GRID.y - 1)))
			var frame: Vector2 = map.ndos_to_frame(uv)
			if frame == Vector2(-1, -1):
				check(false, "ND-OS %s: no frame pixel shows it" % [uv * ndos_size])
				continue
			var hit: Vector3 = map.frame_to_ndos(frame)
			var error: float = (Vector2(hit.x, hit.y) - uv).length() * ndos_size.x
			check(error <= 1.0, "ND-OS %s -> frame %s -> off by %.2f px" % [uv * ndos_size, frame, error])


func test_hidden_points_have_no_frame_point() -> void:
	var map := _map()
	check_eq(map.ndos_to_frame(Vector2(0, 0)), Vector2(-1, -1), "the picture's corner is under the bezel")
	check_eq(map.glass_to_frame(Vector2(-0.5, 0.5)), Vector2(-1, -1), "far outside the raster")


func test_on_picture_bounds() -> void:
	check(GlassMap.on_picture(Vector3(0.0, 0.0, 1.0)), "the first pixel")
	check(not GlassMap.on_picture(Vector3(1.0, 0.5, 1.0)), "one past the last column")
	check(not GlassMap.on_picture(Vector3(0.5, 1.0, 1.0)), "one past the last row")
	check(not GlassMap.on_picture(Vector3(-0.001, 0.5, 1.0)), "left of the picture")
	check(not GlassMap.on_picture(Vector3(0.5, 0.5, GlassMap.MIN_COVERAGE - 0.01)), "barely glass")
