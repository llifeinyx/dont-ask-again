class_name LauncherBadge
extends Control
## The round badge on a launcher slot: a count of new items, ObServer's red "!", or a padlock.

enum Kind { COUNT, ALERT, LOCK }

const ALERT_TEXT := "!"

@export var circle: Texture2D
@export var alert_circle: Texture2D
@export var kind: Kind = Kind.COUNT:
	set(value):
		kind = value
		_update()
@export var count: int = 0:
	set(value):
		count = value
		_update()

@onready var _circle: TextureRect = $Circle
@onready var _text: Label = $Text
@onready var _padlock: TextureRect = $Padlock


func _ready() -> void:
	_update()


func _update() -> void:
	if not is_node_ready():
		return
	_circle.texture = alert_circle if kind == Kind.ALERT else circle
	_text.visible = kind != Kind.LOCK
	_padlock.visible = kind == Kind.LOCK
	_text.text = ALERT_TEXT if kind == Kind.ALERT else str(count)
	_text.theme_type_variation = &"BadgeAlert" if kind == Kind.ALERT else &"BadgeCount"
