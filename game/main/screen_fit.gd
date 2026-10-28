class_name ScreenFit
extends RefCounted
## Window sizing for windowed mode: the frame keeps its 16:9 shape.

const ASPECT := Vector2i(16, 9)
## Share of the usable screen the window may take.
const WINDOW_SHARE: float = 0.8


## Largest 16:9 size, in whole aspect steps, that fits in WINDOW_SHARE of the screen.
static func windowed_size(screen: Vector2i) -> Vector2i:
	var room := Vector2(screen) * WINDOW_SHARE
	var steps: int = floori(minf(room.x / ASPECT.x, room.y / ASPECT.y))
	return ASPECT * maxi(steps, 1)
