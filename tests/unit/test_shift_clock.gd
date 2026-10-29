extends TestCase

var _changes: int = 0


func _clock(hour: int, minute: int) -> ShiftClock:
	var settings := ClockSettings.new()
	settings.start_month = 10
	settings.start_day = 17
	settings.start_hour = hour
	settings.start_minute = minute
	var clock := ShiftClock.new()
	clock.settings = settings
	clock.changed.connect(func() -> void: _changes += 1)
	return clock


func test_mockup_format() -> void:
	var clock := _clock(9, 0)
	check_eq(clock.text(), "10/17  9:00 AM", "the Figma mockup's clock")
	clock.free()


func test_noon_and_midnight() -> void:
	var noon := _clock(12, 5)
	check_eq(noon.text(), "10/17  12:05 PM", "noon is 12 PM")
	noon.free()
	var evening := _clock(22, 0)
	check_eq(evening.text(), "10/17  10:00 PM", "22:00")
	evening.free()
	var midnight := _clock(23, 59)
	midnight.elapsed = 60.0
	check_eq(midnight.text(), "10/18  12:00 AM", "midnight is 12 AM of the next day")
	midnight.free()


func test_runs_at_the_set_speed() -> void:
	var clock := _clock(9, 0)
	clock.elapsed = 59.9
	check_eq(clock.text(), "10/17  9:00 AM", "a minute is not over yet")
	clock.elapsed = 60.0
	check_eq(clock.text(), "10/17  9:01 AM", "real time: one minute per minute")
	clock.settings.game_minutes_per_second = 1.0
	clock.elapsed = 90.0
	check_eq(clock.text(), "10/17  10:30 AM", "one game minute per second")
	clock.free()


func test_changed_only_when_the_minute_changes() -> void:
	var clock := _clock(9, 0)
	_changes = 0
	clock.elapsed = 10.0
	clock.elapsed = 20.0
	check_eq(_changes, 0, "same minute")
	clock.elapsed = 61.0
	check_eq(_changes, 1, "next minute")
	clock.free()
