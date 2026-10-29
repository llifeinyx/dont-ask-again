class_name LauncherSlot
extends BaseButton
## One program on the ND-OS launcher. An open slot shows hover and press and can be the active program;
## a locked one is dimmed, carries a padlock and ignores the mouse.

@export var program: NdosDesktop.Program = NdosDesktop.Program.NONE
@export var icon: Texture2D:
	set(value):
		icon = value
		_update()
@export var locked: bool = false:
	set(value):
		locked = value
		disabled = value
		_update()

## The program running in the program area.
var active: bool = false:
	set(value):
		active = value
		_update()
## New items; 0 hides the badge.
var badge_count: int = 0:
	set(value):
		badge_count = value
		_update()
## ObServer's red "!", shown instead of the count.
var alert: bool = false:
	set(value):
		alert = value
		_update()

@onready var _hover: Control = $Hover
@onready var _content: Control = $Content
@onready var _tile: CanvasGroup = $Content/Tile
@onready var _back: Control = $Content/Tile/Back
@onready var _icon: TextureRect = $Content/Tile/Icon
@onready var _dashes: TextureRect = $Content/Tile/Dashes
@onready var _badge: LauncherBadge = $Content/Badge
@onready var _lock_badge: LauncherBadge = $Content/LockBadge
@onready var _active_left: Control = $ActiveLeft
@onready var _active_right: Control = $ActiveRight


func _ready() -> void:
	_dashes.self_modulate = NdosTokens.LAUNCHER_SLOT_LINE
	button_down.connect(_update)
	button_up.connect(_update)
	_update()


func _notification(what: int) -> void:
	# Runs after BaseButton has updated its own hover state.
	if what == NOTIFICATION_MOUSE_ENTER or what == NOTIFICATION_MOUSE_EXIT:
		_update()


func _update() -> void:
	if not is_node_ready():
		return
	var mode: DrawMode = get_draw_mode()
	var pressing: bool = mode == DRAW_PRESSED or mode == DRAW_HOVER_PRESSED
	_hover.visible = not locked and (pressing or mode == DRAW_HOVER)
	_content.position.y = NdosTokens.SLOT_PRESS_OFFSET if pressing else 0
	_icon.texture = icon
	_tile.self_modulate.a = NdosTokens.LOCKED_OPACITY if locked else 1.0
	_back.visible = locked
	_dashes.visible = locked
	_lock_badge.visible = locked
	_badge.visible = not locked and (alert or badge_count > 0)
	_badge.kind = LauncherBadge.Kind.ALERT if alert else LauncherBadge.Kind.COUNT
	_badge.count = badge_count
	_active_left.visible = active
	_active_right.visible = active
