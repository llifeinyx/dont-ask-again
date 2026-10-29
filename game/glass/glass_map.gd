class_name GlassMap
extends RefCounted
## Where ND-OS sits on the glass, from the same glass UV pass the front frame draws with, so clicks
## and the picture never disagree. The pass holds (u·m, v·m, m) per frame pixel: the ND-OS position
## (0..1, top-left origin) times the glass coverage m.

## A frame pixel counts as glass when at least this much of it is covered.
const MIN_COVERAGE: float = 0.5
## Newton steps for ndos_to_frame; each one roughly squares the error.
const INVERSE_STEPS: int = 12
## Frame pixels between the samples of the local slope in ndos_to_frame.
const SLOPE_STEP: int = 4

var frame_size: Vector2i
## Top-left corner of the view (what the player sees) in the frame.
var view_origin: Vector2i

var _pass: Image


static func load_default(manifest: FrontManifest) -> GlassMap:
	var texture: Texture2D = load(FrontFrame.GLASS_UV_PATH)
	return GlassMap.new(texture.get_image(), manifest)


func _init(uv_pass: Image, manifest: FrontManifest) -> void:
	_pass = uv_pass
	frame_size = manifest.frame_size
	# The view sits in the middle of the frame; the export keeps the margins even.
	view_origin = Vector2i((Vector2(manifest.frame_size - manifest.view_size) / 2.0).round())


## The frame pixel under a point of the view. sway is the camera's shift inside the frame margin.
func view_to_frame(view_position: Vector2, sway: Vector2 = Vector2.ZERO) -> Vector2:
	return view_position + Vector2(view_origin) + sway


## ND-OS position (0..1) and glass coverage at a frame point; coverage 0 off the glass.
func frame_to_ndos(frame_position: Vector2) -> Vector3:
	var pixel := Vector2i(frame_position.floor())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= frame_size.x or pixel.y >= frame_size.y:
		return Vector3.ZERO
	var c: Color = _pass.get_pixel(pixel.x, pixel.y)
	if c.b <= 0.0:
		return Vector3.ZERO
	return Vector3(c.r / c.b, c.g / c.b, c.b)


## Whether a frame point is on the glass.
func is_glass(frame_position: Vector2) -> bool:
	return frame_to_ndos(frame_position).z >= MIN_COVERAGE


## The frame point that shows an ND-OS position (0..1), found by Newton steps on the pass; for tests
## and the click bot. Returns (-1, -1) when the position is not on the glass.
func ndos_to_frame(uv: Vector2) -> Vector2:
	var glass_center: Vector2 = _glass_center()
	var point: Vector2 = glass_center
	for i: int in INVERSE_STEPS:
		var here: Vector3 = frame_to_ndos(point)
		var right: Vector3 = frame_to_ndos(point + Vector2(SLOPE_STEP, 0))
		var down: Vector3 = frame_to_ndos(point + Vector2(0, SLOPE_STEP))
		if here.z <= 0.0 or right.z <= 0.0 or down.z <= 0.0:
			# Near the edge: step back towards the centre and look again.
			point = point.lerp(glass_center, 0.5)
			continue
		var du := Vector2(right.x - here.x, down.x - here.x) / SLOPE_STEP
		var dv := Vector2(right.y - here.y, down.y - here.y) / SLOPE_STEP
		var jacobian := Transform2D(Vector2(du.x, dv.x), Vector2(du.y, dv.y), Vector2.ZERO)
		var error := Vector2(here.x, here.y) - uv
		point -= jacobian.affine_inverse().basis_xform(error)
	# Newton lands within a pixel; the pass is per pixel, so pick the closest of the neighbours.
	var best := Vector2(-1, -1)
	var best_error: float = INF
	var center: Vector2 = point.floor() + Vector2(0.5, 0.5)
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var candidate: Vector2 = center + Vector2(dx, dy)
			var hit: Vector3 = frame_to_ndos(candidate)
			var error: float = Vector2(hit.x, hit.y).distance_squared_to(uv)
			if hit.z >= MIN_COVERAGE and error < best_error:
				best = candidate
				best_error = error
	return best


func _glass_center() -> Vector2:
	return Vector2(frame_size) / 2.0
