class_name Glass
extends Control
## The CRT tube between ND-OS and the front frame. It turns the ND-OS picture into what the tube shows
## (CrtPreset), measures how bright it is for the screen light, and carries the mouse from the frame
## through the glass to ND-OS. It covers the whole view and takes the mouse everywhere.

enum Strength { FULL, SOFT, OFF }

## Samples across and down for the screen's mean brightness; ScreenSurface.average_reference was
## measured on the same grid.
const AVERAGE_GRID := Vector2i(80, 60)
## Where ND-OS sees the cursor once it has left the glass: above and left of the picture.
const OFF_PICTURE := Vector2(-1, -1)
## Different noise patterns before they repeat.
const NOISE_SEEDS: float = 1000.0

@export var full: CrtPreset
@export var soft: CrtPreset
@export var off: CrtPreset
## Where ND-OS sits on the tube; the picture and the mouse both follow it.
@export var fit: GlassFit
@export var strength: Strength = Strength.FULL:
	set(value):
		strength = value
		_apply_preset()

## Picks the CRT noise pattern; it moves on every frame. Screenshots stop the glass and set it.
var noise_seed: float = 0.0:
	set(value):
		noise_seed = value
		if is_node_ready():
			_crt.set_shader_parameter("noise_seed", value)

var _map: GlassMap
var _ndos: SubViewport
var _on_glass: bool = false
var _last_ndos_position := Vector2.ZERO
## Buttons whose press ND-OS got; only their releases follow, wherever the mouse is let go.
var _pressed_buttons: int = 0

@onready var _glow_across: SubViewport = $GlowAcross
@onready var _glow_down: SubViewport = $GlowDown
@onready var _picture: SubViewport = $Picture
@onready var _average: SubViewport = $Average
@onready var _blur_across: ShaderMaterial = ($GlowAcross/Blur as ColorRect).material as ShaderMaterial
@onready var _blur_down: ShaderMaterial = ($GlowDown/Blur as ColorRect).material as ShaderMaterial
@onready var _crt: ShaderMaterial = ($Picture/Crt as ColorRect).material as ShaderMaterial
@onready var _mean: ShaderMaterial = ($Average/Mean as ColorRect).material as ShaderMaterial


func _ready() -> void:
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	_map = GlassMap.load_default(manifest, fit)
	for viewport: SubViewport in [_glow_across, _glow_down]:
		viewport.size = NdosTokens.SCREEN_SIZE
	_picture.size = fit.picture_size
	fit.apply_to(_crt)
	_crt.set_shader_parameter("phosphor_black", fit.phosphor_black)
	_blur_down.set_shader_parameter("source", _glow_across.get_texture())
	_crt.set_shader_parameter("glow", _glow_down.get_texture())
	_crt.set_shader_parameter("screen_size", Vector2(NdosTokens.SCREEN_SIZE))
	_mean.set_shader_parameter("grid", AVERAGE_GRID)
	_crt.set_shader_parameter("noise_seed", noise_seed)
	_apply_preset()


func _process(_delta: float) -> void:
	noise_seed = fposmod(noise_seed + 1.0, NOISE_SEEDS)


## Shows this ND-OS viewport on the tube and sends it the mouse.
func show_ndos(ndos: SubViewport) -> void:
	_ndos = ndos
	var source: Texture2D = ndos.get_texture()
	_blur_across.set_shader_parameter("source", source)
	_crt.set_shader_parameter("picture", source)
	_mean.set_shader_parameter("picture", source)


## What the tube shows over the glass UV pass, in display sRGB.
func picture() -> Texture2D:
	return _picture.get_texture()


## A 1×1 texture with the mean linear luminance of ND-OS.
func average() -> Texture2D:
	return _average.get_texture()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null or _ndos == null:
		return
	accept_event()
	var hit: Vector3 = _map.frame_to_ndos(_map.view_to_frame(mouse.position))
	var button := mouse as InputEventMouseButton
	if not GlassMap.on_picture(hit):
		_leave_glass()
		# A press that began on the picture still ends when the button is let go off it, away from every
		# control, so the pressed one cancels instead of firing or showing hover again.
		if button != null and not button.pressed and _pressed_buttons & _mask(button):
			_forward(mouse, OFF_PICTURE)
		return
	_forward(mouse, Vector2(hit.x, hit.y) * Vector2(NdosTokens.SCREEN_SIZE))


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_leave_glass()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_cycle_crt"):
		strength = wrapi(strength + 1, 0, Strength.size()) as Strength
		get_viewport().set_input_as_handled()


func _forward(event: InputEventMouse, ndos_position: Vector2) -> void:
	var forwarded: InputEventMouse = event.duplicate()
	forwarded.position = ndos_position
	forwarded.global_position = ndos_position
	var button := forwarded as InputEventMouseButton
	if button != null:
		if button.pressed:
			_pressed_buttons |= _mask(button)
		else:
			_pressed_buttons &= ~_mask(button)
	var motion := forwarded as InputEventMouseMotion
	if motion != null:
		motion.relative = ndos_position - _last_ndos_position if _on_glass else Vector2.ZERO
		_on_glass = true
	_last_ndos_position = ndos_position
	_ndos.push_input(forwarded, true)


func _leave_glass() -> void:
	if _on_glass and _ndos != null:
		# notify_mouse_exited() alone leaves the last control hovered in a SubViewport fed by push_input,
		# so the cursor also moves off the picture.
		var away := InputEventMouseMotion.new()
		away.position = OFF_PICTURE
		away.global_position = OFF_PICTURE
		_ndos.push_input(away, true)
		_ndos.notify_mouse_exited()
	_on_glass = false


func _apply_preset() -> void:
	if not is_node_ready():
		return
	var preset: CrtPreset = [full, soft, off][strength]
	_blur_across.set_shader_parameter("direction", Vector2(1, 0))
	_blur_down.set_shader_parameter("direction", Vector2(0, 1))
	# Figma's blur radius is two sigmas.
	for blur: ShaderMaterial in [_blur_across, _blur_down]:
		blur.set_shader_parameter("sigma", preset.glow_blur / 2.0)
	var uniforms: Array[String] = CrtPreset.uniforms_of(_crt.shader)
	for property: String in uniforms:
		_crt.set_shader_parameter(property, preset.get(property))


static func _mask(button: InputEventMouseButton) -> int:
	return 1 << (button.button_index - 1)
