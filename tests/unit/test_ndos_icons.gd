extends TestCase
## Eye pixels come from Figma's SVG; their colours must be the Figma variables in NdosTokens.


func test_eye_uses_the_variables() -> void:
	_check_colors("eye_open", [NdosTokens.EYE_ON])


func _check_colors(icon: String, allowed: Array[Color]) -> void:
	var texture: Texture2D = load("res://assets/ndos/icons/%s.png" % icon)
	var image: Image = texture.get_image()
	var found: Dictionary[String, bool] = {}
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a > 0.0:
				found[pixel.to_html(false)] = true
	var expected: Dictionary[String, bool] = {}
	for color: Color in allowed:
		expected[color.to_html(false)] = true
	check_eq(found, expected, "%s colours" % icon)
