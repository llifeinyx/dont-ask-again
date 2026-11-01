extends TestCase

## ND-OS points for the round trip: corners, edge middles and the centre.
const POINTS: Array[Vector2] = [
	Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1),
	Vector2(0.5, 0), Vector2(0, 0.5), Vector2(1, 0.5), Vector2(0.5, 1), Vector2(0.5, 0.5),
]
## Scales the round trip must hold at.
const SCALES: Array[float] = [0.9, 1.0, 1.1]
## Round-trip error allowed, in ND-OS pixels.
const ROUND_TRIP_PIXELS: float = 0.001
## ND-OS points that must stay in view: the outer corners of the "ND-OS" label and of the clock, the
## content nearest the picture's corners (measured on tests/reference/ndos_idle.png).
const CORNER_CONTENT: Array[Vector2] = [Vector2(21, 13), Vector2(1264, 13)]
## The raster may reach at most this many ND-OS pixels under the bezel on any side.
const OVERSCAN_PIXELS: float = 8.0


func _fit() -> GlassFit:
	return load("res://game/glass/fit.tres")


func _map(fit: GlassFit) -> GlassMap:
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	return GlassMap.load_default(manifest, fit)


func test_round_trip() -> void:
	var fit: GlassFit = _fit().duplicate()
	var ndos_size := Vector2(NdosTokens.SCREEN_SIZE)
	for scale: float in SCALES:
		fit.picture_scale = scale
		check_eq(fit.glass_to_ndos(GlassFit.HALF), GlassFit.HALF, "scale %s: the centre stays" % scale)
		for point: Vector2 in POINTS:
			var back: Vector2 = fit.glass_to_ndos(fit.ndos_to_glass(point))
			var error: float = ((back - point) * ndos_size).length()
			check(error < ROUND_TRIP_PIXELS, "scale %s, ND-OS %s: off by %.5f px" % [scale, point, error])


func test_no_black_border_shows() -> void:
	var fit := _fit()
	var ndos_size := Vector2(NdosTokens.SCREEN_SIZE)
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for glass_uv: Vector2 in _map(fit).glass_edge():
		var ndos: Vector2 = fit.glass_to_ndos(glass_uv)
		low = low.min(ndos)
		high = high.max(ndos)
	check(low.x >= 0.0 and low.y >= 0.0 and high.x <= 1.0 and high.y <= 1.0,
		"the glass edge shows only ND-OS: %s..%s" % [low, high])
	var under_bezel: Vector2 = low.max(Vector2.ONE - high) * ndos_size
	check(under_bezel.x <= OVERSCAN_PIXELS and under_bezel.y <= OVERSCAN_PIXELS,
		"at most %s px under the bezel: %s..%s" % [OVERSCAN_PIXELS, low * ndos_size, high * ndos_size])


func test_corner_content_stays_in_view() -> void:
	var fit := _fit()
	var map := _map(fit)
	var ndos_size := Vector2(NdosTokens.SCREEN_SIZE)
	for point: Vector2 in CORNER_CONTENT:
		var frame: Vector2 = map.ndos_to_frame(point / ndos_size)
		var hit: Vector3 = map.frame_to_ndos(frame)
		var error: float = (Vector2(hit.x, hit.y) * ndos_size - point).length()
		check(frame.x >= 0.0 and hit.z >= GlassMap.MIN_COVERAGE and error <= 1.0,
			"ND-OS %s: frame %s, coverage %s, off by %.2f px" % [point, frame, hit.z, error])
