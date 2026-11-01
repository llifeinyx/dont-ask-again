class_name GlassMap
extends RefCounted
## Where ND-OS sits on the glass, from the same glass UV pass the front frame draws with and the same
## GlassFit the CRT picture is bent by, so clicks and the picture never disagree. The pass holds
## (u·m, v·m, m) per frame pixel: the glass position (0..1, top-left origin) times the glass coverage m.

## A frame pixel counts as glass when at least this much of it is covered.
const MIN_COVERAGE: float = 0.5
## Newton steps for ndos_to_frame; each one roughly squares the error.
const INVERSE_STEPS: int = 12
## Times a step that leaves the glass may be halved before the search gives up on it.
const STEP_HALVINGS: int = 12
## Frame pixels between the samples of the local slope in ndos_to_frame.
const SLOPE_STEP: int = 4
## How far, in glass UV, the closest frame pixel may show from the asked point: about two ND-OS pixels.
## Farther means the point is hidden under the bezel.
const LANDING_TOLERANCE: float = 0.002

var frame_size: Vector2i
## Top-left corner of the view (what the player sees) in the frame.
var view_origin: Vector2i

var fit: GlassFit

var _pass: Image


static func load_default(manifest: FrontManifest, glass_fit: GlassFit) -> GlassMap:
	var texture: Texture2D = load(FrontFrame.GLASS_UV_PATH)
	return GlassMap.new(texture.get_image(), manifest, glass_fit)


## Whether a frame_to_ndos() result is a point of the ND-OS picture: on the glass, inside the picture.
static func on_picture(hit: Vector3) -> bool:
	return hit.z >= MIN_COVERAGE and hit.x >= 0.0 and hit.y >= 0.0 and hit.x <= 1.0 and hit.y <= 1.0


func _init(uv_pass: Image, manifest: FrontManifest, glass_fit: GlassFit) -> void:
	_pass = uv_pass
	fit = glass_fit
	frame_size = manifest.frame_size
	# The view sits in the middle of the frame; the export keeps the margins even.
	view_origin = Vector2i((Vector2(manifest.frame_size - manifest.view_size) / 2.0).round())


## The frame pixel under a point of the view. sway is the camera's shift inside the frame margin.
func view_to_frame(view_position: Vector2, sway: Vector2 = Vector2.ZERO) -> Vector2:
	return view_position + Vector2(view_origin) + sway


## ND-OS position (0..1 on the picture) and glass coverage at a frame point; coverage 0 off the glass.
func frame_to_ndos(frame_position: Vector2) -> Vector3:
	var hit: Vector3 = frame_to_glass(frame_position)
	if hit.z <= 0.0:
		return Vector3.ZERO
	var ndos: Vector2 = fit.glass_to_ndos(Vector2(hit.x, hit.y))
	return Vector3(ndos.x, ndos.y, hit.z)


## Glass position (0..1) and glass coverage at a frame point, as the pass stores them.
func frame_to_glass(frame_position: Vector2) -> Vector3:
	var pixel := Vector2i(frame_position.floor())
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= frame_size.x or pixel.y >= frame_size.y:
		return Vector3.ZERO
	var c: Color = _pass.get_pixel(pixel.x, pixel.y)
	if c.b <= 0.0:
		return Vector3.ZERO
	return Vector3(c.r / c.b, c.g / c.b, c.b)


## Whether a frame point is on the glass.
func is_glass(frame_position: Vector2) -> bool:
	return frame_to_glass(frame_position).z >= MIN_COVERAGE


## Glass positions of the frame pixels on the glass edge: covered at least MIN_COVERAGE, not fully.
func glass_edge() -> PackedVector2Array:
	var image: Image = _pass
	if image.get_format() != Image.FORMAT_RGBF:
		image = _pass.duplicate()
		image.convert(Image.FORMAT_RGBF)
	var values: PackedFloat32Array = image.get_data().to_float32_array()
	var edge := PackedVector2Array()
	for i: int in range(0, values.size(), 3):
		var m: float = values[i + 2]
		if m >= MIN_COVERAGE and m < 1.0:
			edge.append(Vector2(values[i], values[i + 1]) / m)
	return edge


## The frame point that shows an ND-OS position (0..1); for tests and the click bot. Returns (-1, -1)
## when the position is not on the glass.
func ndos_to_frame(ndos_uv: Vector2) -> Vector2:
	return glass_to_frame(fit.ndos_to_glass(ndos_uv))


## The frame point that shows a glass position (0..1), found by Newton steps on the pass. Returns
## (-1, -1) when no frame pixel shows it.
func glass_to_frame(uv: Vector2) -> Vector2:
	var point: Vector2 = _glass_center()
	for i: int in INVERSE_STEPS:
		var slopes: Variant = _slopes(point)
		if slopes == null:
			break
		var jacobian: Transform2D = slopes
		var here: Vector3 = frame_to_glass(point)
		var step: Vector2 = jacobian.affine_inverse().basis_xform(Vector2(here.x, here.y) - uv)
		# A full step can leave the glass (the target may sit under the bezel): shorten it until it stays.
		for j: int in STEP_HALVINGS:
			if _slopes(point - step) != null:
				break
			step /= 2.0
		point -= step
	# Newton lands within a pixel; the pass is per pixel, so pick the closest of the neighbours.
	var best := Vector2(-1, -1)
	var best_error: float = INF
	var center: Vector2 = point.floor() + Vector2(0.5, 0.5)
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			var candidate: Vector2 = center + Vector2(dx, dy)
			var hit: Vector3 = frame_to_glass(candidate)
			var error: float = Vector2(hit.x, hit.y).distance_squared_to(uv)
			if hit.z >= MIN_COVERAGE and error < best_error:
				best = candidate
				best_error = error
	return best if best_error <= LANDING_TOLERANCE * LANDING_TOLERANCE else Vector2(-1, -1)


## How the pass changes per frame pixel at a point, as a Transform2D basis; null off the glass.
func _slopes(point: Vector2) -> Variant:
	var here: Vector3 = frame_to_glass(point)
	var right: Vector3 = frame_to_glass(point + Vector2(SLOPE_STEP, 0))
	var down: Vector3 = frame_to_glass(point + Vector2(0, SLOPE_STEP))
	if here.z <= 0.0 or right.z <= 0.0 or down.z <= 0.0:
		return null
	var du := Vector2(right.x - here.x, down.x - here.x) / SLOPE_STEP
	var dv := Vector2(right.y - here.y, down.y - here.y) / SLOPE_STEP
	return Transform2D(Vector2(du.x, dv.x), Vector2(du.y, dv.y), Vector2.ZERO)


func _glass_center() -> Vector2:
	return Vector2(frame_size) / 2.0
