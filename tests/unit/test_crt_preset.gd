extends TestCase


func _preset(name: String) -> CrtPreset:
	return load("res://game/glass/presets/%s.tres" % name)


func test_full_is_the_figma_frame() -> void:
	var full := _preset("full")
	check_eq(full.scanline_opacity, 0.16, "scanlines: black at 16%")
	check_eq(full.scanline_period, 3, "every 3 px")
	check_eq(full.glow_opacity, 0.35, "glow at 35%")
	check_eq(full.glow_blur, 8.0, "layer blur 8")
	check_eq([full.vignette_start, full.vignette_mid, full.vignette_mid_opacity, full.vignette_edge_opacity],
		[0.7, 0.93, 0.22, 0.55], "vignette stops")
	check_eq([full.noise_opacity, full.noise_density], [0.07, 0.5], "noise")
	check_eq([full.tube_radius, full.edge_shadow_opacity, full.edge_shadow_blur], [64.0, 0.7, 36.0], "edge shadow")
	check_eq([full.edge_light_opacity, full.edge_light_blur, full.edge_light_offset], [0.08, 10.0, 4.0], "edge light")


func test_soft_halves_and_off_clears() -> void:
	var full := _preset("full")
	var soft := _preset("soft")
	var off := _preset("off")
	for property: String in ["scanline_opacity", "glow_opacity", "vignette_mid_opacity", "vignette_edge_opacity",
			"noise_opacity", "edge_shadow_opacity", "edge_light_opacity"]:
		var full_value: float = full.get(property)
		var soft_value: float = soft.get(property)
		var off_value: float = off.get(property)
		check(is_equal_approx(soft_value, full_value / 2.0), "soft %s is half of full" % property)
		check_eq(off_value, 0.0, "off has no %s" % property)
