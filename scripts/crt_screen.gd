extends ColorRect
## The CRT glass of the room photo. Shows the ND-OS viewport through crt.gdshader and
## maps mouse input back through the same barrel warp into ND-OS coordinates (640x480).

const F := 640.0 / 1067.0                  # room photo pixels -> viewport units
const GLASS := Vector4(535.5 * F, 300.0 * F, 321.0 * F, 256.0 * F)
const ACTIVE := Vector4(535.5 * F, 293.0 * F, 288.0 * F, 216.0 * F)
const BARREL := 0.045
const UI_SIZE := Vector2(640, 480)

var ndos
var power := 1.0
var flicker := 1.0
var _mat: ShaderMaterial


func setup(ui_texture: Texture2D, room_texture: Texture2D, os_node) -> void:
	ndos = os_node
	position = Vector2(GLASS.x - GLASS.z, GLASS.y - GLASS.w)
	size = Vector2(GLASS.z, GLASS.w) * 2.0
	color = Color.WHITE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mouse_filter = Control.MOUSE_FILTER_STOP
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://shaders/crt.gdshader")
	_mat.set_shader_parameter("ui_tex", ui_texture)
	_mat.set_shader_parameter("room_tex", room_texture)
	_mat.set_shader_parameter("rect_pos", position)
	_mat.set_shader_parameter("rect_size", size)
	_mat.set_shader_parameter("glass", GLASS)
	_mat.set_shader_parameter("active", ACTIVE)
	_mat.set_shader_parameter("barrel", BARREL)
	material = _mat
	gui_input.connect(_on_gui_input)


func _process(_delta: float) -> void:
	if _mat != null:
		_mat.set_shader_parameter("power", power)
		_mat.set_shader_parameter("flicker", flicker)


## Viewport point -> ND-OS point, or (-1, -1) outside the picture.
static func to_ui(p: Vector2) -> Vector2:
	var u := (p - Vector2(ACTIVE.x, ACTIVE.y)) / Vector2(ACTIVE.z, ACTIVE.w)
	var r2 := u.dot(u)
	var s := u * (1.0 + BARREL * r2) / (1.0 + BARREL * 2.0)
	if absf(s.x) > 1.0 or absf(s.y) > 1.0:
		return Vector2(-1, -1)
	return (s * 0.5 + Vector2(0.5, 0.5)) * UI_SIZE


func _on_gui_input(ev: InputEvent) -> void:
	if ndos == null or not ndos.power_on:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
		return
	var mm := ev as InputEventMouseMotion
	if mm != null:
		var q := to_ui(position + mm.position)
		var over: bool = q.x >= 0.0 and ndos.is_clickable(q)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if over else Control.CURSOR_ARROW
		return
	var mb := ev as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var q := to_ui(position + mb.position)
		if q.x >= 0.0:
			ndos.click(q)
