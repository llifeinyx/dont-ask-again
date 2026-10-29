class_name FrontLighting
extends Node
## Light state of the front frame. Game code changes mode; the frame listens to changed and puts
## state into its shader.

signal changed

enum Mode { NORMAL, FLICKER, LAMP_OFF }

@export var normal: LightingPreset
@export var lamp_off: LightingPreset
@export var flicker: FlickerPattern
@export var mode: Mode = Mode.NORMAL:
	set(value):
		mode = value
		flicker_time = 0.0

## Seconds since the flicker started. Screenshots and tests set it directly.
var flicker_time: float = 0.0:
	set(value):
		flicker_time = value
		_update()

## The light right now. Other nodes only read it.
var state := LightingPreset.new()


func _ready() -> void:
	_update()


func _process(delta: float) -> void:
	if mode == Mode.FLICKER:
		flicker_time += delta


func _update() -> void:
	var preset: LightingPreset = lamp_off if mode == Mode.LAMP_OFF else normal
	# Setters run while the scene loads, before every export is assigned.
	if preset == null or flicker == null:
		return
	state.lamp = preset.lamp * (flicker.sample(flicker_time) if mode == Mode.FLICKER else 1.0)
	state.lamp_tint = preset.lamp_tint
	state.screen = preset.screen
	state.base = preset.base
	state.world = preset.world
	state.indicator = preset.indicator
	changed.emit()
