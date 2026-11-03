extends TestCase
## The screen light's reference brightness is the idle Desktop's, measured the way the glass does it.

const IDLE_GOLDEN := "res://tests/golden/ndos_idle.png"
## Allowed relative difference.
const TOLERANCE: float = 0.01


func test_reference_is_the_idle_desktop() -> void:
	var surface: ScreenSurface = load("res://game/front/screen.tres")
	var image := Image.load_from_file(ProjectSettings.globalize_path(IDLE_GOLDEN))
	var grid: Vector2i = Glass.AVERAGE_GRID
	var sum: float = 0.0
	for y: int in grid.y:
		for x: int in grid.x:
			var uv: Vector2 = (Vector2(x, y) + Vector2(0.5, 0.5)) / Vector2(grid)
			var pixel := Vector2i((uv * Vector2(image.get_size())).floor())
			var linear: Color = image.get_pixelv(pixel).srgb_to_linear()
			sum += linear.r * 0.2126 + linear.g * 0.7152 + linear.b * 0.0722
	var average: float = sum / (grid.x * grid.y)
	check(absf(average / surface.average_reference - 1.0) <= TOLERANCE,
		"idle Desktop averages %.6f, screen.tres says %.6f" % [average, surface.average_reference])
