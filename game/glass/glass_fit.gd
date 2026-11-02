class_name GlassFit
extends Resource
## Where the flat ND-OS picture sits in the tube's lit raster. The glass UV pass already follows the
## curved glass (Blender unwraps the raster along it, 0..1, reaching a few pixels under the bezel), so
## this only scales the picture about the raster's centre and fills the rest with phosphor black.
## game/shaders/glass_fit.gdshaderinc does the same maths on the GPU.

const HALF := Vector2(0.5, 0.5)

## Share of the raster the picture spans along each axis; 1 fills it exactly.
@export_range(0.5, 1.5) var picture_scale: float = 1.0
## The tube outside the picture.
@export var phosphor_black: Color = Color("#050505")
## Size of the tube's picture drawn over the glass: about the glass's size in the frame, so the picture
## is resampled once at the density the player sees.
@export var picture_size: Vector2i = Vector2i(1600, 1200)


## ND-OS position (0..1 inside the picture) at a point of the glass UV pass; outside 0..1 off it.
func glass_to_ndos(glass_uv: Vector2) -> Vector2:
	return HALF + (glass_uv - HALF) / picture_scale


## The glass UV point that shows an ND-OS position; the inverse of glass_to_ndos.
func ndos_to_glass(ndos_uv: Vector2) -> Vector2:
	return HALF + (ndos_uv - HALF) * picture_scale


## Sets the uniforms of game/shaders/glass_fit.gdshaderinc.
func apply_to(material: ShaderMaterial) -> void:
	material.set_shader_parameter("glass_picture_scale", picture_scale)
