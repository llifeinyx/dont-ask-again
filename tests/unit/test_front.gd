extends TestCase
## FrontFrame maps pixel rectangles of the export onto texture coordinates.


func test_uv_rect() -> void:
	check_eq(FrontFrame.uv_rect(Rect2(0, 0, 100, 400), Vector2(100, 400)), Vector4(0, 0, 1, 1), "whole image")
	check_eq(FrontFrame.uv_rect(Rect2(25, 50, 50, 200), Vector2(100, 400)), Vector4(0.25, 0.125, 0.5, 0.5),
		"inner rectangle")


func test_view_rect_of_the_export() -> void:
	# 2560x1440 in the middle of 2816x1584 leaves 5% of the view on each side.
	var view: Vector4 = FrontFrame.uv_rect(Rect2(128, 72, 2560, 1440), Vector2(2816, 1584))
	check(view.is_equal_approx(Vector4(1.0 / 22.0, 1.0 / 22.0, 10.0 / 11.0, 10.0 / 11.0)), "view rect %s" % view)
