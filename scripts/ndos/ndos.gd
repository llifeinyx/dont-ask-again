extends Control
## ND-OS: the operator's desktop, drawn inside the CRT (SubViewport 1280x960).
## Everything is custom-drawn in logical 640x480 units; S.K converts to pixels.
## No windows, no menus: a taskbar (KONTUR eye, mail, clock), a launcher with four
## programs (and three locked ones), and the active program filling the rest.

const S := preload("res://scripts/ndos/nd_style.gd")
const EchoApp := preload("res://scripts/ndos/echo_app.gd")
const KonturApp := preload("res://scripts/ndos/kontur_app.gd")
const FeedApp := preload("res://scripts/ndos/feed_app.gd")
const SeeyaApp := preload("res://scripts/ndos/seeya_app.gd")

const APP_ICONS := [
	preload("res://art/icons/app_echo.png"), preload("res://art/icons/app_kontur.png"),
	preload("res://art/icons/app_feed.png"), preload("res://art/icons/app_seeya.png")]
const LOCKED_ICONS := [
	preload("res://art/icons/locked_terminal.png"), preload("res://art/icons/locked_files.png"),
	preload("res://art/icons/locked_settings.png")]
const LOCKED_NAMES := ["terminal", "files", "settings"]
const EYE_OPEN := preload("res://art/icons/eye_open.png")
const EYE_CLOSED := preload("res://art/icons/eye_closed.png")
const ENVELOPE := preload("res://art/icons/envelope.png")

var shift
var echo
var kontur
var feed
var seeya
var apps: Array = []
var active := 0
var modal = null            # an object with draw_modal() and modal_key(ev)
var hits: Array = []        # [{"rect": Rect2 (logical), "cb": Callable}]
var anchors: Dictionary = {} # name -> Rect2 (logical): places the onboarding can point at
var hint: Dictionary = {}    # {"target": anchor name, "text": caption}; empty = no hint
var toasts: Array = []      # [{"text", "kind", "life"}]
var cw := 4.5               # logical width of one terminal column
var cols := 120
var time := 0.0
var power_on := true


func setup(owner_shift, content: Dictionary) -> void:
	shift = owner_shift
	echo = EchoApp.new()
	kontur = KonturApp.new()
	feed = FeedApp.new()
	seeya = SeeyaApp.new()
	apps = [echo, kontur, feed, seeya]
	for a in apps:
		a.setup(self, shift, content)


func _ready() -> void:
	size = Vector2(S.W, S.H) * S.K
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	cw = S.MONO.get_string_size("M", HORIZONTAL_ALIGNMENT_LEFT, -1, S.MONO_PX).x / S.K
	cols = int((S.X1 - S.X0 - 24.0) / cw)


func _process(delta: float) -> void:
	time += delta
	for t in toasts.duplicate():
		t["life"] = float(t["life"]) - delta
		if float(t["life"]) <= 0.0:
			toasts.erase(t)
	queue_redraw()


## Called by the shift every frame. Program logic only runs while there is power,
## except labeling time, which the shift keeps counting.
func tick(delta: float) -> void:
	if power_on:
		echo.tick(delta)
		kontur.tick(delta)
		seeya.tick(delta)
	feed.tick(delta)


func open_app(i: int) -> void:
	if i < 0 or i >= apps.size():
		return
	active = i
	apps[i].on_open()
	Sfx.play("click", -12.0)


func toast(text: String, kind: String) -> void:
	toasts.append({"text": text, "kind": kind, "life": 8.0 if kind == "kontur" else 6.0})
	while toasts.size() > 3:
		toasts.pop_front()


func clear_toasts() -> void:
	toasts.clear()


# --- input ----------------------------------------------------------------------

func handle_key(ev: InputEventKey) -> bool:
	if not power_on or not ev.pressed:
		return false
	if modal != null:
		modal.modal_key(ev)
		return true
	if ev.ctrl_pressed and ev.keycode >= KEY_1 and ev.keycode <= KEY_4:
		open_app(ev.keycode - KEY_1)
		return true
	return apps[active].key(ev)


func click(p: Vector2) -> void:
	if not power_on:
		return
	for i in range(hits.size() - 1, -1, -1):
		var h: Dictionary = hits[i]
		if (h["rect"] as Rect2).has_point(p):
			(h["cb"] as Callable).call()
			return


func is_clickable(p: Vector2) -> bool:
	for h in hits:
		if (h["rect"] as Rect2).has_point(p):
			return true
	return false


# --- drawing: chrome ---------------------------------------------------------------

func _draw() -> void:
	hits.clear()
	anchors.clear()
	if not power_on:
		draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
		return
	draw_rect(Rect2(Vector2.ZERO, size), S.CHROME_BG)
	_draw_panel()
	_draw_launcher()
	rect(Rect2(S.X0, S.Y0, S.X1 - S.X0, S.Y1 - S.Y0), S.TBG)
	apps[active].draw()
	_draw_toasts()
	if modal != null:
		hits.clear()
		anchors.clear()
		rect(Rect2(0, 0, S.W, S.H), Color(0, 0, 0, 0.66))
		_draw_eye(true, Color8(240, 80, 64))
		modal.draw_modal()
	_draw_hint()


func _clock_x() -> float:
	return 634.0 - text_width("Tue " + shift.clock_text(), S.UI, 16) - 14.0


func _draw_panel() -> void:
	var w := S.W * S.K
	var h := 18.0 * S.K
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([S.PANEL_TOP, S.PANEL_TOP, S.PANEL_BOT, S.PANEL_BOT]))
	text(10, 9, "ND-OS", S.PANEL_TXT, S.UI_B, 14)
	text(634, 9, "Tue " + shift.clock_text(), S.PANEL_TXT, S.UI, 16, 2)
	var x := _clock_x()
	tex(ENVELOPE, Rect2(x - 12, 3, 13, 12), S.ENVELOPE)
	if seeya.unread_count() > 0:
		draw_circle(Vector2(x, 4) * S.K, 2.4 * S.K, S.ENVELOPE)
	hit(Rect2(x - 14, 0, 18, 18), open_app.bind(3))
	anchor("envelope", Rect2(x - 14, 1, 18, 16))
	_draw_eye(kontur.watching, S.EYE_ON if kontur.watching else S.EYE_OFF)


func _draw_eye(open: bool, color: Color) -> void:
	var cx := _clock_x() - 30.0
	if open:
		tex(EYE_OPEN, Rect2(cx - 8, 4, 16, 10), color)
	else:
		tex(EYE_CLOSED, Rect2(cx - 8, 5, 16, 10), color)
	hit(Rect2(cx - 10, 0, 20, 18), open_app.bind(1))
	anchor("eye", Rect2(cx - 11, 1, 22, 16))


func _draw_launcher() -> void:
	rect(Rect2(0, 18, 44, S.H - 18), S.LAUNCHER)
	for i in apps.size():
		var y := 40.0 + i * 42.0
		tex(APP_ICONS[i], Rect2(6, y - 15, 32, 30))
		if i == active:
			poly([Vector2(0, y - 3.5), Vector2(3.5, y), Vector2(0, y + 3.5)], S.PANEL_TXT)
			poly([Vector2(44, y - 3.5), Vector2(40.5, y), Vector2(44, y + 3.5)], S.CHROME_BG)
		var b: String = apps[i].badge()
		if b != "":
			var red := b == "!"
			var bw := text_width(b, S.UI_B, 14) + 8.0
			rrect(Rect2(40 - bw, y - 19, bw + 1, 10), S.BADGE_RED if red else S.BADGE_BG, S.BADGE_LINE, 5.0)
			text(40.5 - bw / 2.0, y - 14, b, Color.WHITE if red else S.DARK, S.UI_B, 14, 1)
		hit(Rect2(4, y - 18, 38, 36), open_app.bind(i))
		anchor("launcher_%d" % i, Rect2(3, y - 19, 38, 38))
	for i in LOCKED_ICONS.size():
		var y := 236.0 + i * 40.0
		tex(LOCKED_ICONS[i], Rect2(6, y - 15, 32, 30))
		hit(Rect2(4, y - 17, 38, 34), _locked.bind(LOCKED_NAMES[i]))


func _locked(app_name: String) -> void:
	Sfx.play("error", -10.0)
	toast("%s: access restricted to the system. Operator role: decisions only." % app_name, "auto")


func _draw_toasts() -> void:
	var y := S.Y0 + 6.0
	var w := 232.0
	var x := S.X1 - w - 8.0
	var tcols := int((w - 16.0) / cw)
	for t in toasts:
		var kind := String(t["kind"])
		var lines := S.wrap(String(t["text"]), tcols)
		if lines.size() > 3:
			lines = lines.slice(0, 3)
		var hgt := 12.0 + (lines.size() + 1) * S.LH
		var border: Color = {"kontur": S.RED, "auto": S.ACC, "mail": S.DIM}.get(kind, S.DIM)
		var title: String = {"kontur": "KONTUR", "auto": "echo.daemon", "mail": "seeya.legacy"}.get(kind, "")
		var r := Rect2(x, y, w, hgt)
		rect(r.grow(2), S.TBG)
		rrect(r, S.TBG, border, 3.0)
		text(x + 8, y + 6 + S.LH * 0.5, title, border, S.MONO_B, S.MONO_PX)
		for i in lines.size():
			text(x + 8, y + 6 + S.LH * (i + 1.5), lines[i], S.FG, S.MONO, S.MONO_PX)
		hit(r, _toast_clicked.bind(t))
		y += hgt + 4.0


func _toast_clicked(t: Dictionary) -> void:
	toasts.erase(t)
	match String(t["kind"]):
		"kontur":
			open_app(1)
		"mail":
			open_app(3)
		_:
			open_app(0)


## Onboarding: a pulsing frame around the place to click and a short caption next to it.
func _draw_hint() -> void:
	if hint.is_empty() or not anchors.has(String(hint["target"])):
		return
	var r: Rect2 = anchors[String(hint["target"])]
	var pulse := 0.5 + 0.5 * sin(time * 5.0)
	var c := Color(S.ACC, 0.55 + 0.45 * pulse)
	rrect(r.grow(1.5 + pulse), Color(0, 0, 0, 0), c, 3.0, 1.2)
	var caption := String(hint.get("text", ""))
	if caption == "":
		return
	var w := text_width(caption) + 12.0
	var h := S.LH + 4.0
	# To the right of the target when it fits, otherwise below (or above near the bottom).
	var pos := Vector2(r.end.x + 8.0, r.get_center().y - h / 2.0)
	if pos.x + w > S.W - 4.0:
		pos = Vector2(r.position.x, r.end.y + 5.0)
		if pos.y + h > S.H - 2.0:
			pos.y = r.position.y - h - 5.0
	pos.x = clampf(pos.x, 2.0, S.W - w - 2.0)
	var box := Rect2(pos, Vector2(w, h))
	rrect(box, S.TBG, c, 3.0)
	text(box.position.x + 6.0, box.get_center().y, caption, S.ACC)


# --- drawing primitives (logical units) ---------------------------------------------

func rect(r: Rect2, color: Color, filled := true, width := 1.0) -> void:
	var pr := Rect2(r.position * S.K, r.size * S.K)
	if filled:
		draw_rect(pr, color)
	else:
		draw_rect(pr, color, false, width * S.K)


func rrect(r: Rect2, fill: Color, border := Color(0, 0, 0, 0), radius := 4.0, border_w := 0.8) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(radius * S.K))
	if border.a > 0.0:
		sb.border_color = border
		sb.set_border_width_all(maxi(1, int(round(border_w * S.K))))
	sb.anti_aliasing = true
	draw_style_box(sb, Rect2(r.position * S.K, r.size * S.K))


func line(a: Vector2, b: Vector2, color: Color, width := 0.6) -> void:
	draw_line(a * S.K, b * S.K, color, maxf(1.0, width * S.K))


func poly(points: Array, color: Color) -> void:
	var p := PackedVector2Array()
	for v in points:
		p.append(v * S.K)
	draw_colored_polygon(p, color)


func tex(t: Texture2D, r: Rect2, modulate_color := Color.WHITE) -> void:
	draw_texture_rect(t, Rect2(r.position * S.K, r.size * S.K), false, modulate_color)


func text_width(s: String, f: Font = S.MONO, px: int = S.MONO_PX) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x / S.K


## Draws text vertically centered on y. align: 0 left, 1 center, 2 right.
func text(x: float, y: float, s: String, color: Color, f: Font = S.MONO, px: int = S.MONO_PX, align := 0) -> void:
	var px_x := x * S.K
	if align != 0:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		px_x -= w if align == 2 else w / 2.0
	var base := y * S.K + (f.get_ascent(px) - f.get_descent(px)) / 2.0
	draw_string(f, Vector2(px_x, base), s, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func hit(r: Rect2, cb: Callable) -> void:
	hits.append({"rect": r, "cb": cb})


## Names a drawn area so the onboarding hint can point at it. Several calls with the same
## name merge into one rect.
func anchor(anchor_name: String, r: Rect2) -> void:
	anchors[anchor_name] = (anchors[anchor_name] as Rect2).merge(r) if anchors.has(anchor_name) else r


# --- terminal grid helpers (rows/cols inside the app area) ----------------------------

func lx() -> float:
	return S.X0 + 12.0


func ry(row: float) -> float:
	return S.Y0 + 14.0 + row * S.LH


func cx(col: float) -> float:
	return lx() + col * cw


func put(row: float, col: float, s: String, color: Color = S.FG, bold := false) -> void:
	text(cx(col), ry(row), s, color, S.MONO_B if bold else S.MONO)


## parts: [[text, color, bold?], ...]. Returns the column after the last part.
func segs(row: float, parts: Array, col := 0.0) -> float:
	for p in parts:
		var t := String(p[0])
		put(row, col, t, p[1], p.size() > 2 and bool(p[2]))
		col += t.length()
	return col


func rput(row: float, s: String, color: Color = S.FG, bold := false, end_col := -1.0) -> void:
	var e := float(cols) if end_col < 0.0 else end_col
	put(row, e - s.length(), s, color, bold)


func frame(r0: float, r1: float, c0 := 0.0, c1 := -1.0, color: Color = S.FAINT) -> void:
	var e := float(cols) if c1 < 0.0 else c1
	rrect(Rect2(cx(c0 + 0.5), ry(r0), (e - c0 - 1.0) * cw, ry(r1) - ry(r0)), Color(0, 0, 0, 0), color, 4.0)


func hline(row: float, color: Color = S.FAINT) -> void:
	line(Vector2(lx(), ry(row)), Vector2(S.X1 - 12.0, ry(row)), color)


func bar(row: float, col: float, ncols: float, frac: float, color: Color) -> void:
	var x0 := cx(col)
	var w := ncols * cw
	rect(Rect2(x0, ry(row) - 2.5, w, 5), S.BAR_BG)
	rect(Rect2(x0, ry(row) - 2.5, w * clampf(frac, 0.0, 1.0), 5), color)


func row_bg(row: float, c0: float, c1: float, color: Color) -> void:
	rect(Rect2(cx(c0), ry(row) - S.LH / 2.0 + 0.6, (c1 - c0) * cw, S.LH - 1.2), color)


func cursor(row: float, col: float) -> void:
	if fmod(time, 1.0) < 0.6:
		rect(Rect2(cx(col), ry(row) - 5, cw, 10), S.FG)


func hit_row(row: float, c0: float, c1: float, cb: Callable) -> void:
	hit(Rect2(cx(c0), ry(row) - S.LH / 2.0, (c1 - c0) * cw, S.LH), cb)


func anchor_row(anchor_name: String, row: float, c0: float, c1: float) -> void:
	anchor(anchor_name, Rect2(cx(c0), ry(row) - S.LH / 2.0, (c1 - c0) * cw, S.LH))


## Bottom input line ("> typed_") and the hint line, as in the Echo mockup.
func footer(left: String, right := "", typed := "", show_cursor := true) -> void:
	var yb := S.Y1 - 34.0
	line(Vector2(lx(), yb - 8), Vector2(S.X1 - 12, yb - 8), S.FAINT)
	line(Vector2(lx(), yb + 8), Vector2(S.X1 - 12, yb + 8), S.FAINT)
	text(lx(), yb, ">", S.DIM)
	if typed != "":
		text(lx() + 2.0 * cw, yb, typed, S.FG)
	if show_cursor and fmod(time, 1.0) < 0.6:
		rect(Rect2(lx() + (2.0 + typed.length()) * cw, yb - 5, cw, 10), S.FG)
	text(lx(), S.Y1 - 14, left, S.FAINT)
	if right != "":
		text(S.X1 - 12, S.Y1 - 14, right, S.DIM, S.MONO, S.MONO_PX, 2)


## Draws prepared rows: {"parts": [[text, color, bold?]], "col": float, "hit": Callable,
## "bg": Color (diff line background), "bar": [col, ncols, frac, color], "anchor": String}.
func draw_row(row: float, spec: Dictionary) -> void:
	var col := float(spec.get("col", 0.0))
	if spec.has("bg"):
		row_bg(row, col, cols - 2.0, spec["bg"])
	segs(row, spec.get("parts", []), col)
	if spec.has("bar"):
		var b: Array = spec["bar"]
		bar(row, float(b[0]), float(b[1]), float(b[2]), b[3])
	if spec.has("hit"):
		hit_row(row, col, cols, spec["hit"])
	if spec.has("anchor"):
		var n := 0
		for p in spec.get("parts", []):
			n += String(p[0]).length()
		anchor_row(String(spec["anchor"]), row, col, col + n + 1.0)
	for h in spec.get("hits", []):
		hit_row(row, float(h[0]), float(h[1]), h[2])


## Word-wrapped text as row specs. First row gets `lead` parts, the rest are indented.
func wrap_rows(lead: Array, body: String, color: Color, bold := false, col := 0.0, suffix: Array = []) -> Array:
	var lead_len := 0
	for p in lead:
		lead_len += String(p[0]).length()
	var width := maxi(8, cols - int(col) - lead_len - 2)
	var lines := S.wrap(body, width)
	var out: Array = []
	for i in lines.size():
		var parts: Array = []
		if i == 0:
			parts.append_array(lead)
		parts.append([lines[i], color, bold])
		if i == lines.size() - 1:
			parts.append_array(suffix)
		out.append({"parts": parts, "col": col if i == 0 else col + lead_len})
	return out


## Number of terminal rows usable for content between the header and the footer.
func content_rows() -> int:
	return int((S.Y1 - 44.0 - (S.Y0 + 14.0)) / S.LH)
