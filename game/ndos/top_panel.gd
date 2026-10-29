class_name TopPanel
extends PanelContainer
## The ND-OS system panel: the "ND-OS" title, the ObServer eye and the clock.

var time_text: String = "":
	set(value):
		time_text = value
		if is_node_ready():
			_clock.text = value

@onready var _clock: Label = $Row/Clock


func _ready() -> void:
	_clock.text = time_text
