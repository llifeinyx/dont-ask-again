class_name ShiftClock
extends Node
## Game time of the shift, shown in the ND-OS top panel as month/day and time without the year,
## for example "10/17  9:00 AM". Screenshots and tests stop it and set elapsed by hand.

## Emitted when the shown minute changes.
signal changed

const SECONDS_PER_MINUTE: int = 60
const HOURS_PER_HALF_DAY: int = 12
const NOON: int = 12

@export var settings: ClockSettings:
	set(value):
		settings = value
		_update()

## Real seconds since the shift started.
var elapsed: float = 0.0:
	set(value):
		elapsed = value
		_update()

var _shown: String = ""


func _process(delta: float) -> void:
	elapsed += delta


## The clock as the top panel shows it.
func text() -> String:
	return _shown


## Unix time of the current game minute.
func game_time() -> int:
	var start: int = Time.get_unix_time_from_datetime_dict({
		"year": settings.start_year, "month": settings.start_month, "day": settings.start_day,
		"hour": settings.start_hour, "minute": settings.start_minute, "second": 0,
	})
	return start + floori(elapsed * settings.game_minutes_per_second) * SECONDS_PER_MINUTE


static func format(unix_time: int) -> String:
	var date: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	var month: int = date["month"]
	var day: int = date["day"]
	var hour: int = date["hour"]
	var minute: int = date["minute"]
	var half_day_hour: int = hour % HOURS_PER_HALF_DAY
	return "%d/%d  %d:%02d %s" % [
		month, day, HOURS_PER_HALF_DAY if half_day_hour == 0 else half_day_hour, minute,
		"AM" if hour < NOON else "PM"]


func _update() -> void:
	if settings == null:
		return
	var shown: String = format(game_time())
	if shown != _shown:
		_shown = shown
		changed.emit()
