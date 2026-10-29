class_name ClockSettings
extends Resource
## When the shift starts on the ND-OS clock and how fast game time runs. The year is never shown; it
## only makes the calendar maths right. The start must be a real date: Godot rejects 2/31 with an error.

@export var start_year: int = 2026
@export_range(1, 12) var start_month: int = 1
@export_range(1, 31) var start_day: int = 1
@export_range(0, 23) var start_hour: int = 0
@export_range(0, 59) var start_minute: int = 0
## Game minutes that pass in one real second; 1/60 is real time.
@export var game_minutes_per_second: float = 1.0 / 60.0
