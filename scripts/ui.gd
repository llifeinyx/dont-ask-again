extends RefCounted
## Shared palette, theme and small widget helpers.

# Same palette as ND-OS (scripts/ndos/nd_style.gd). Old names kept for compatibility.
const BG := Color8(13, 13, 12)
const GREEN := Color8(205, 172, 92)        # highlight (mustard)
const GREEN_DIM := Color8(112, 109, 102)
const GREEN_DARK := Color8(34, 33, 30)
const TEXT := Color8(198, 196, 188)
const MUTED := Color8(112, 109, 102)
const AMBER := Color8(205, 172, 92)
const RED := Color8(206, 92, 74)
const RED_DIM := Color8(130, 60, 50)


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = preload("res://fonts/DejaVuSansMono.ttf")
	t.default_font_size = 9

	t.set_color("font_color", "Label", TEXT)
	t.set_color("default_color", "RichTextLabel", TEXT)
	t.set_stylebox("normal", "RichTextLabel", StyleBoxEmpty.new())

	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", GREEN)
	t.set_color("font_pressed_color", "Button", BG)
	t.set_color("font_hover_pressed_color", "Button", BG)
	t.set_color("font_focus_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", GREEN_DIM)
	t.set_stylebox("normal", "Button", box(GREEN_DARK, GREEN_DIM))
	t.set_stylebox("hover", "Button", box(Color8(40, 36, 26), GREEN))
	t.set_stylebox("pressed", "Button", box(GREEN, GREEN))
	t.set_stylebox("hover_pressed", "Button", box(GREEN, GREEN))
	t.set_stylebox("disabled", "Button", box(BG, GREEN_DARK))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	t.set_color("font_color", "LineEdit", GREEN)
	t.set_color("caret_color", "LineEdit", GREEN)
	t.set_color("font_placeholder_color", "LineEdit", GREEN_DIM)
	t.set_stylebox("normal", "LineEdit", box(BG, GREEN_DIM))
	t.set_stylebox("focus", "LineEdit", box(BG, GREEN))

	t.set_stylebox("background", "ProgressBar", box(BG, GREEN_DARK, 0.0))
	t.set_stylebox("fill", "ProgressBar", box(GREEN_DIM, GREEN_DIM, 0.0))
	t.set_stylebox("panel", "PanelContainer", box(BG, GREEN_DARK))
	t.set_constant("separation", "VBoxContainer", 2)
	t.set_constant("separation", "HBoxContainer", 4)
	return t


static func box(bg: Color, border: Color, margin: float = 3.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = margin
	s.content_margin_right = margin
	s.content_margin_top = minf(margin, 2.0)
	s.content_margin_bottom = minf(margin, 2.0)
	return s


static func label(text: String, font_size: int = 9, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrap_label(text: String, width: float, font_size: int = 9, color: Color = TEXT) -> Label:
	var l := label(text, font_size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(width, 0)
	return l


static func button(text: String, callback: Callable, font_size: int = 9) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	b.pressed.connect(callback)
	return b


static func bar() -> ProgressBar:
	var p := ProgressBar.new()
	p.show_percentage = false
	p.min_value = 0.0
	p.max_value = 1.0
	p.value = 1.0
	p.custom_minimum_size = Vector2(0, 3)
	return p


static func panel(bg: Color = BG, border: Color = GREEN_DARK) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(bg, border))
	return p


static func place(c: Control, rect: Rect2) -> Control:
	c.position = rect.position
	c.size = rect.size
	return c


static func full_rect(c: Control) -> Control:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return c
