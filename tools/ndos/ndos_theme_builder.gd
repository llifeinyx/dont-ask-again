class_name NdosThemeBuilder
## Builds the ND-OS theme from NdosTokens. tools/ndos/build_theme.gd saves it as assets/ndos/theme.tres,
## and a unit test checks that the saved theme still matches the tokens.

const THEME_PATH := "res://assets/ndos/theme.tres"
const FONT_PATH := "res://assets/ndos/fonts/PixelifySans.ttf"


static func build() -> Theme:
	var theme := Theme.new()
	var semibold: FontVariation = _weight(NdosTokens.WEIGHT_SEMIBOLD)
	var medium: FontVariation = _weight(NdosTokens.WEIGHT_MEDIUM)
	theme.default_font = semibold
	theme.default_font_size = NdosTokens.TITLE_SIZE
	theme.set_constant("separation", "VBoxContainer", 0)
	theme.set_constant("separation", "HBoxContainer", 0)

	_variation(theme, "NdosBackground", "Panel")
	theme.set_stylebox("panel", "NdosBackground", _flat(NdosTokens.CHROME_BG))

	_variation(theme, "TopPanel", "PanelContainer")
	theme.set_stylebox("panel", "TopPanel", _top_panel())
	_variation(theme, "TopPanelRow", "HBoxContainer")
	theme.set_constant("separation", "TopPanelRow", NdosTokens.TOP_PANEL_GAP)
	_label(theme, "PanelTitle", semibold, NdosTokens.TITLE_SIZE, NdosTokens.PANEL_TEXT)
	_label(theme, "PanelClock", medium, NdosTokens.CLOCK_SIZE, NdosTokens.PANEL_TEXT)

	_variation(theme, "Launcher", "PanelContainer")
	var launcher: StyleBoxFlat = _flat(NdosTokens.LAUNCHER_BG)
	launcher.content_margin_top = NdosTokens.LAUNCHER_PADDING_TOP
	theme.set_stylebox("panel", "Launcher", launcher)
	_variation(theme, "LauncherSlots", "VBoxContainer")
	theme.set_constant("separation", "LauncherSlots", NdosTokens.LAUNCHER_SLOT_GAP)

	_variation(theme, "SlotTile", "Panel")
	var tile: StyleBoxFlat = _flat(NdosTokens.LAUNCHER_SLOT)
	tile.set_corner_radius_all(NdosTokens.SLOT_TILE_RADIUS)
	theme.set_stylebox("panel", "SlotTile", tile)
	_variation(theme, "SlotHover", "Panel")
	var hover := StyleBoxFlat.new()
	hover.draw_center = false
	hover.border_color = NdosTokens.SLOT_HOVER_LINE
	hover.set_border_width_all(NdosTokens.SLOT_HOVER_WIDTH)
	hover.set_corner_radius_all(NdosTokens.SLOT_HOVER_RADIUS)
	# Hard pixel steps on the corners, like the rest of the pixel art.
	hover.anti_aliasing = false
	theme.set_stylebox("panel", "SlotHover", hover)
	_label(theme, "BadgeCount", semibold, NdosTokens.BADGE_SIZE, NdosTokens.DARK)
	_label(theme, "BadgeAlert", semibold, NdosTokens.BADGE_SIZE, NdosTokens.PANEL_TEXT)

	_variation(theme, "AppArea", "Panel")
	var app: StyleBoxFlat = _flat(NdosTokens.APP_BG)
	app.border_color = NdosTokens.CHROME_BG
	app.border_width_left = NdosTokens.APP_AREA_BORDER
	app.border_width_top = NdosTokens.APP_AREA_BORDER
	theme.set_stylebox("panel", "AppArea", app)
	return theme


static func _weight(weight: int) -> FontVariation:
	var font := FontVariation.new()
	font.base_font = load(FONT_PATH)
	font.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return font


static func _variation(theme: Theme, type_name: StringName, base: StringName) -> void:
	theme.set_type_variation(type_name, base)


static func _label(theme: Theme, type_name: StringName, font: Font, size: int, color: Color) -> void:
	_variation(theme, type_name, "Label")
	theme.set_font("font", type_name, font)
	theme.set_font_size("font_size", type_name, size)
	theme.set_color("font_color", type_name, color)


static func _flat(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	return box


static func _top_panel() -> StyleBoxTexture:
	var colors: PackedColorArray = StepGradient.rows(NdosTokens.TOP_PANEL_STEPS, NdosTokens.TOP_PANEL_HEIGHT)
	var image := Image.create_empty(1, NdosTokens.TOP_PANEL_HEIGHT, false, Image.FORMAT_RGB8)
	for y: int in colors.size():
		image.set_pixel(0, y, colors[y])
	var box := StyleBoxTexture.new()
	box.texture = ImageTexture.create_from_image(image)
	box.content_margin_left = NdosTokens.TOP_PANEL_PADDING_LEFT
	box.content_margin_right = NdosTokens.TOP_PANEL_PADDING_RIGHT
	return box
