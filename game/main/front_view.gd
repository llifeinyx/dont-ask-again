class_name FrontView
extends Control
## The front frame with ND-OS on its glass: wires the parts together. main.tscn shows it; tests and
## screenshots use it as it is.

@onready var front: FrontFrame = $Front
@onready var glass: Glass = $Glass
@onready var desktop: NdosDesktop = $Ndos/Desktop
@onready var _ndos: SubViewport = $Ndos


func _ready() -> void:
	_ndos.size = NdosTokens.SCREEN_SIZE
	glass.show_ndos(_ndos)
	front.show_screen(glass.picture(), glass.average())
