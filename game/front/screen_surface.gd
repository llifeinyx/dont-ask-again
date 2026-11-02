class_name ScreenSurface
extends Resource
## The lit glass when ND-OS is on it: how bright the screen light layer is for a given picture.

## Mean linear luminance of the idle Desktop (the Figma mockup state), sampled the way
## game/glass/screen_average.gdshader does. That picture lights the room exactly as Blender rendered
## the screen layer; a brighter one lights it more.
@export var average_reference: float = 0.012279
