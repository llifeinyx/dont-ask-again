class_name ScreenSurface
extends Resource
## The lit glass when ND-OS is on it: how bright the screen light layer is for a given picture, and the
## lamp's soft highlight on the tube (Figma "ND-OS Desktop / CRT", layer "Lamp reflection").

## Mean linear luminance of the idle Desktop (the Figma mockup state), sampled the way
## game/glass/screen_average.gdshader does. That picture lights the room exactly as Blender rendered
## the screen layer; a brighter one lights it more.
@export var average_reference: float = 0.012279
## The highlight's ellipse in ND-OS pixels over the whole glass; it fades linearly from the centre to
## its rim.
@export var reflection_rect: Rect2 = Rect2(120, 40, 760, 420)
## Its colour, picked as sRGB like any colour in the inspector.
@export var reflection_color: Color = Color("#fff5e0")
## Linear light of the highlight's centre at full lamp, for reflection_color made linear. Chosen so
## that over the dark program area it gives what Figma's 10% screen blend gives (37, 36, 33).
@export var reflection_strength: float = 0.0353
