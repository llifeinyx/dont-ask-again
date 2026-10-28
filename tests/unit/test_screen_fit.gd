extends TestCase


func test_common_screens() -> void:
	check_eq(ScreenFit.windowed_size(Vector2i(1920, 1080)), Vector2i(1536, 864), "1080p")
	check_eq(ScreenFit.windowed_size(Vector2i(2560, 1440)), Vector2i(2048, 1152), "1440p")
	check_eq(ScreenFit.windowed_size(Vector2i(3840, 2160)), Vector2i(3072, 1728), "4K")


func test_keeps_aspect_on_odd_screens() -> void:
	for screen: Vector2i in [Vector2i(1366, 768), Vector2i(2560, 1080), Vector2i(1280, 1024), Vector2i(1280, 800)]:
		var size: Vector2i = ScreenFit.windowed_size(screen)
		check_eq(size.x * 9, size.y * 16, "16:9 on %s" % screen)
		check(size.x <= screen.x and size.y <= screen.y, "fits %s" % screen)


func test_tiny_screen_still_gets_a_window() -> void:
	check_eq(ScreenFit.windowed_size(Vector2i(10, 10)), Vector2i(16, 9), "minimum")
