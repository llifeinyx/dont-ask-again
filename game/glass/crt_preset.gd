class_name CrtPreset
extends Resource
## How strongly the CRT changes the ND-OS picture. "Full" carries the numbers of the Figma frame
## "ND-OS Desktop / CRT" (2:114); sizes are in ND-OS pixels. Opacities of 0 switch an effect off.

## Black rows, scanline_period pixels apart from the top row.
@export_range(0.0, 1.0) var scanline_opacity: float = 0.16
@export_range(2, 8) var scanline_period: int = 3
## A blurred copy of the picture, screen-blended on top.
@export_range(0.0, 1.0) var glow_opacity: float = 0.35
## Figma's layer blur radius; the gaussian's sigma is half of it.
@export_range(0.0, 32.0) var glow_blur: float = 8.0
## Radial darkening from the centre (0) to the corners of the inscribed ellipse (1): clear up to
## vignette_start, vignette_mid_opacity at vignette_mid, vignette_edge_opacity from 1 on.
@export_range(0.0, 1.0) var vignette_start: float = 0.7
@export_range(0.0, 1.0) var vignette_mid: float = 0.93
@export_range(0.0, 1.0) var vignette_mid_opacity: float = 0.22
@export_range(0.0, 1.0) var vignette_edge_opacity: float = 0.55
## Fine white noise, changing every frame: each pixel gets white at a random share of
## noise_opacity × noise_density, like Figma's monotone noise effect.
@export_range(0.0, 1.0) var noise_opacity: float = 0.07
@export_range(0.0, 1.0) var noise_density: float = 0.5
## Inner shadows along the tube's rounded edge (Figma's radius 64).
@export_range(0.0, 128.0) var tube_radius: float = 64.0
@export_range(0.0, 1.0) var edge_shadow_opacity: float = 0.7
@export_range(0.0, 128.0) var edge_shadow_blur: float = 36.0
@export var edge_light_color: Color = Color("#fff2d9")
@export_range(0.0, 1.0) var edge_light_opacity: float = 0.08
@export_range(0.0, 64.0) var edge_light_blur: float = 10.0
## The warm edge light is a shadow cast from this far up, so it lines the top edge.
@export_range(0.0, 16.0) var edge_light_offset: float = 4.0


## The preset's properties that the shader has as uniforms, by name; glow_blur goes to the blur passes.
static func uniforms_of(shader: Shader) -> Array[String]:
	var names: Array[String] = []
	for uniform: Dictionary in shader.get_shader_uniform_list():
		var uniform_name: String = uniform["name"]
		names.append(uniform_name)
	var shared: Array[String] = []
	for property: Dictionary in CrtPreset.new().get_property_list():
		var usage: int = property["usage"]
		var property_name: String = property["name"]
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE and property_name in names:
			shared.append(property_name)
	return shared

