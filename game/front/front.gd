class_name FrontFrame
extends Control
## The front frame: Blender light layers summed in linear light, the picture on the glass, the mug over
## them, then AgX. Lighting decides how strong each layer is. Without show_screen() the glass stays
## dark, as Blender rendered it.

const MANIFEST_PATH := "res://assets/front/manifest.tres"
const LUT_PATH := "res://assets/front/agx_punchy_65.bin"
const INVERSE_LUT_PATH := "res://assets/front/agx_punchy_inverse_65.bin"
const GLASS_UV_PATH := "res://assets/front/glass_uv.exr"

@export var surface: ScreenSurface

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
	Lut3D.load_file(INVERSE_LUT_PATH).apply_to(_composite, "agx_inverse_lut")
	_composite.set_shader_parameter("glass_uv", load(GLASS_UV_PATH))
	_composite.set_shader_parameter("exposure", manifest.exposure)
	var ndos_size := Vector2(NdosTokens.SCREEN_SIZE)
	_composite.set_shader_parameter("reflection_rect", uv_rect(surface.reflection_rect, ndos_size))
	var reflection: Color = surface.reflection_color.srgb_to_linear()
	_composite.set_shader_parameter("reflection_color", Vector3(reflection.r, reflection.g, reflection.b))
	_composite.set_shader_parameter("reflection_strength", surface.reflection_strength)
	_composite.set_shader_parameter("average_reference", surface.average_reference)
	_lighting.changed.connect(_apply_lighting)
	_apply_lighting()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("debug_cycle_lamp"):
		_lighting.mode = wrapi(_lighting.mode + 1, 0, FrontLighting.Mode.size()) as FrontLighting.Mode
		get_viewport().set_input_as_handled()


## Puts a picture on the glass: display sRGB over the glass UV pass. average is a 1×1 texture with its mean
## linear luminance, which the screen light follows.
func show_screen(picture: Texture2D, average: Texture2D) -> void:
	_composite.set_shader_parameter("screen_picture", picture)
	_composite.set_shader_parameter("glass_on", 1.0)
	_lighting.screen_average = average


func _apply_lighting() -> void:
	var state: LightingPreset = _lighting.state
	var tint: Color = state.lamp_tint.srgb_to_linear() * state.lamp
	_composite.set_shader_parameter("lamp", Vector3(tint.r, tint.g, tint.b))
	_composite.set_shader_parameter("screen", state.screen)
	_composite.set_shader_parameter("base", state.base)
	_composite.set_shader_parameter("world", state.world)
	_composite.set_shader_parameter("indicator", state.indicator)
	_composite.set_shader_parameter("screen_average", _lighting.screen_average)
	_composite.set_shader_parameter("average_on", 0.0 if _lighting.screen_average == null else 1.0)


## Pixel rectangle as (x, y, width, height) in UV of an image of the given size.
static func uv_rect(rect: Rect2, image_size: Vector2) -> Vector4:
	return Vector4(rect.position.x / image_size.x, rect.position.y / image_size.y, rect.size.x / image_size.x, rect.size.y / image_size.y)
