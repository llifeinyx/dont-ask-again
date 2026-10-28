class_name FrontManifest
extends Resource
## What tools/blender/export_front.py put into assets/front. The script writes it; the frame reads it.

## The whole rendered frame, with the margin for camera sway.
@export var frame_size: Vector2i
## The part the player sees, centred in the frame.
@export var view_size: Vector2i
## Where the cropped mug layers sit in the frame, in pixels from the top-left corner.
@export var mug_rect: Rect2i
## Blender's exposure in stops, applied to linear light before AgX.
@export var exposure: float
## Part of ND-OS (0..1, top-left origin) that shows through the glass; the rest is under the bezel.
@export var ndos_visible: Rect2
## A quick low-sample export; it never goes into the repository.
@export var preview: bool
@export var samples: int
## Blend file, Blender version and export time.
@export var source: String
