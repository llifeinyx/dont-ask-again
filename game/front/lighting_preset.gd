class_name LightingPreset
extends Resource
## Strength of each Blender light layer of the front frame. 1 is the light exactly as rendered.

@export_range(0.0, 4.0) var lamp: float = 1.0
## Multiplies the lamp layer's colour; white keeps the rendered colour. Picked as an sRGB colour, like any
## colour in the inspector, and made linear before it touches the light.
@export var lamp_tint: Color = Color.WHITE
@export_range(0.0, 4.0) var screen: float = 1.0
@export_range(0.0, 4.0) var base: float = 1.0
@export_range(0.0, 4.0) var world: float = 1.0
@export_range(0.0, 4.0) var indicator: float = 1.0
