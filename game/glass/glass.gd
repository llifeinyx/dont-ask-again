class_name Glass
extends Control
## The tube between ND-OS and the front frame. It puts the ND-OS picture on the curved glass (GlassFit),
## measures how bright it is for the screen light, and carries the mouse from the frame through the
## glass to ND-OS. It covers the whole view and takes the mouse everywhere.

## Samples across and down for the screen's mean brightness; ScreenSurface.average_reference was
## measured on the same grid.
const AVERAGE_GRID := Vector2i(80, 60)
## Where ND-OS sees the cursor once it has left the glass: above and left of the picture.
const OFF_PICTURE := Vector2(-1, -1)

## Where ND-OS sits on the tube; the picture and the mouse both follow it.
@export var fit: GlassFit

var _map: GlassMap
var _ndos: SubViewport
var _on_glass: bool = false
var _last_ndos_position := Vector2.ZERO
## Buttons whose press ND-OS got; only their releases follow, wherever the mouse is let go.
var _pressed_buttons: int = 0

@onready var _picture: SubViewport = $Picture
@onready var _average: SubViewport = $Average
@onready var _tube: ShaderMaterial = ($Picture/Tube as ColorRect).material as ShaderMaterial
@onready var _mean: ShaderMaterial = ($Average/Mean as ColorRect).material as ShaderMaterial


func _ready() -> void:
	var manifest: FrontManifest = load(FrontFrame.MANIFEST_PATH)
	_map = GlassMap.load_default(manifest, fit)
	_picture.size = fit.picture_size
	fit.apply_to(_tube)
	_tube.set_shader_parameter("phosphor_black", fit.phosphor_black)
	_mean.set_shader_parameter("grid", AVERAGE_GRID)


## Shows this ND-OS viewport on the tube and sends it the mouse.
func show_ndos(ndos: SubViewport) -> void:
	_ndos = ndos
	var source: Texture2D = ndos.get_texture()
	_tube.set_shader_parameter("picture", source)
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


static func _mask(button: InputEventMouseButton) -> int:
	return 1 << (button.button_index - 1)
