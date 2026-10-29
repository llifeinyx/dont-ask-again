extends TestCase

var _changes: int = 0


func _lighting() -> FrontLighting:
	var lighting := FrontLighting.new()
	lighting.normal = load("res://game/front/presets/normal.tres")
	lighting.lamp_off = load("res://game/front/presets/lamp_off.tres")
	lighting.flicker = load("res://game/front/presets/flicker.tres")
	lighting.changed.connect(func() -> void: _changes += 1)
	return lighting


func test_modes() -> void:
	var lighting := _lighting()
	lighting.mode = FrontLighting.Mode.NORMAL
	check_eq(lighting.state.lamp, 1.0, "normal lamp")
	check_eq(lighting.state.base, 1.0, "normal base")
	lighting.mode = FrontLighting.Mode.LAMP_OFF
	check_eq(lighting.state.lamp, 0.0, "lamp off")
	check_eq(lighting.state.base, 1.0, "base light stays on")
	check_eq(lighting.state.screen, 1.0, "screen light stays on")
	lighting.free()


func test_flicker_follows_the_pattern() -> void:
	var lighting := _lighting()
	lighting.mode = FrontLighting.Mode.FLICKER
	for time: float in [0.0, 0.31, 1.7, 4.25]:
		lighting.flicker_time = time
		check(is_equal_approx(lighting.state.lamp, lighting.flicker.sample(time)), "lamp at %.2f s" % time)
	lighting.free()


func test_mode_change_restarts_flicker_and_notifies() -> void:
	var lighting := _lighting()
	lighting.mode = FrontLighting.Mode.FLICKER
	lighting.flicker_time = 3.0
	_changes = 0
	lighting.mode = FrontLighting.Mode.FLICKER
	check_eq(lighting.flicker_time, 0.0, "flicker restarts")
	check(_changes > 0, "changed is emitted")
	lighting.free()
