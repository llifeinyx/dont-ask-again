class_name FrontFrame
extends Control
## The front frame: Blender light layers summed in linear light, the mug over them, then AgX.
## Lighting decides how strong each layer is.

const MANIFEST_PATH := "res://assets/front/manifest.tres"
const LUT_PATH := "res://assets/front/agx_punchy_65.bin"

@onready var _lighting: FrontLighting = $Lighting
@onready var _frame: SubViewport = $Frame
@onready var _composite: ShaderMaterial = ($Frame/Composite as ColorRect).material as ShaderMaterial
@onready var _view: ShaderMaterial = ($View as ColorRect).material as ShaderMaterial


func _ready() -> void:
	var manifest: FrontManifest = load(MANIFEST_PATH)
	var frame_size := Vector2(manifest.frame_size)
	var view_size := Vector2(manifest.view_size)
	_frame.size = manifest.frame_size
	_composite.set_shader_parameter("mug_rect", uv_rect(Rect2(manifest.mug_rect), frame_size))
	_view.set_shader_parameter("view_rect", uv_rect(Rect2((frame_size - view_size) / 2.0, view_size), frame_size))
	_view.set_shader_parameter("exposure", manifest.exposure)
	_view.set_shader_parameter("frame", _frame.get_texture())
	Lut3D.load_file(LUT_PATH).apply_to(_view)
	_lighting.changed.connect(_apply_lighting)
	_apply_lighting()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_cycle_lamp"):
		_lighting.mode = wrapi(_lighting.mode + 1, 0, FrontLighting.Mode.size()) as FrontLighting.Mode
		get_viewport().set_input_as_handled()


func _apply_lighting() -> void:
	var state: LightingPreset = _lighting.state
	var tint: Color = state.lamp_tint.srgb_to_linear() * state.lamp
	_composite.set_shader_parameter("lamp", Vector3(tint.r, tint.g, tint.b))
	_composite.set_shader_parameter("screen", state.screen)
	_composite.set_shader_parameter("base", state.base)
	_composite.set_shader_parameter("world", state.world)
	_composite.set_shader_parameter("indicator", state.indicator)


## Pixel rectangle as (x, y, width, height) in UV of an image of the given size.
static func uv_rect(rect: Rect2, image_size: Vector2) -> Vector4:
	return Vector4(rect.position.x / image_size.x, rect.position.y / image_size.y, rect.size.x / image_size.x, rect.size.y / image_size.y)
