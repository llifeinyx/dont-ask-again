class_name LauncherBadge
extends Control
## The badge on a launcher slot: a count of new items, ObServer's red "!", or a padlock. It is pixel art
## on ND-OS's art grid: a disc with a one-pixel rim, digits from BadgeGlyphs. Two or more glyphs stretch
## the disc into a pill that grows to the left, so the badge keeps its place on the tile's corner. The
## control's rect is the disc; drawn_rect() is what it draws.

enum Kind { COUNT, ALERT, LOCK }

## Art pixels in a shape row: outside, rim, fill.
const OUTSIDE := "."
const RIM := "R"
const FILL := "F"

@export var glyphs: BadgeGlyphs
@export var kind: Kind = Kind.COUNT:
	set(value):
		kind = value
		_update()
@export var count: int = 0:
	set(value):
		count = value
		_update()

@onready var _padlock: TextureRect = $Padlock


## What a badge of this kind and count shows; empty for the padlock.
static func label_for(badge_kind: Kind, badge_count: int) -> String:
	match badge_kind:
		Kind.ALERT:
			return NdosTokens.BADGE_ALERT
		Kind.LOCK:
			return ""
	if badge_count > NdosTokens.BADGE_MAX_COUNT:
		return str(NdosTokens.BADGE_MAX_COUNT) + NdosTokens.BADGE_OVERFLOW
	# A slot hides its badge at 0; a negative count would have no glyph.
	return str(maxi(badge_count, 0))


## The badge's width in art pixels for a text: the disc, or a pill around the text that leaves it
## centred with BADGE_PILL_PADDING clear fill around it, the rounded ends included.
static func width_for(label: String, glyph_set: BadgeGlyphs) -> int:
	var text_width: int = glyph_set.text_width(label, NdosTokens.BADGE_GLYPH_GAP)
	if text_width == 0:
		return NdosTokens.BADGE_DISC
	var width: int = maxi(NdosTokens.BADGE_DISC,
		text_width + 2 * (NdosTokens.BADGE_RIM + NdosTokens.BADGE_PILL_PADDING))
	if (width - text_width) % 2 == 1:
		width += 1
	# Two art pixels at a time keep the label centred.
	while not _text_clear(label, glyph_set, width):
		width += 2
	return width


## Where a text's top-left art pixel sits in a badge this many art pixels wide.
static func text_corner(label: String, glyph_set: BadgeGlyphs, width: int) -> Vector2i:
	var text_width: int = glyph_set.text_width(label, NdosTokens.BADGE_GLYPH_GAP)
	# The room around the label is even, and the disc and the glyphs are both odd in height.
	return Vector2i(floori((width - text_width) / 2.0), floori((NdosTokens.BADGE_DISC - glyph_set.height()) / 2.0))


## Whether every glyph box of a text has only fill within BADGE_PILL_PADDING of it, diagonals included.
## Whole boxes rather than lit pixels, so every count with the same number of digits gets one width.
static func _text_clear(label: String, glyph_set: BadgeGlyphs, width: int) -> bool:
	var rows: PackedStringArray = shape(width)
	var corner: Vector2i = text_corner(label, glyph_set, width)
	var reach: int = NdosTokens.BADGE_PILL_PADDING
	var box := Vector2i(glyph_set.text_width(label, NdosTokens.BADGE_GLYPH_GAP), glyph_set.height())
	for y: int in range(corner.y - reach, corner.y + box.y + reach):
		for x: int in range(corner.x - reach, corner.x + box.x + reach):
			if x < 0 or y < 0 or x >= width or y >= rows.size() or rows[y][x] != FILL:
				return false
	return true


## The badge's shape, one string per row of art pixels: RIM, FILL or OUTSIDE. A pill is the disc cut
## at its middle column with straight rows in between.
static func shape(width: int) -> PackedStringArray:
	var rows := PackedStringArray()
	for row: int in NdosTokens.BADGE_DISC:
		var line: String = ""
		for column: int in width:
			if not _inside(column, row, width):
				line += OUTSIDE
			elif _deep_inside(column, row, width):
				line += FILL
			else:
				line += RIM
		rows.append(line)
	return rows


## Whether every art pixel within BADGE_RIM of this one, straight across or down, is inside the badge.
static func _deep_inside(column: int, row: int, width: int) -> bool:
	for step: int in range(1, NdosTokens.BADGE_RIM + 1):
		if not (_inside(column - step, row, width) and _inside(column + step, row, width)
				and _inside(column, row - step, width) and _inside(column, row + step, width)):
			return false
	return true


## The fill, rim and ink colours of a badge.
static func colors_for(badge_kind: Kind) -> PackedColorArray:
	if badge_kind == Kind.ALERT:
		return PackedColorArray([NdosTokens.BADGE_RED, NdosTokens.BADGE_BG, NdosTokens.PANEL_TEXT])
	return PackedColorArray([NdosTokens.BADGE_BG, NdosTokens.BADGE_LINE, NdosTokens.DARK])


## Whether an art pixel's centre lies inside a badge this many art pixels wide.
static func _inside(column: int, row: int, width: int) -> bool:
	var disc: int = NdosTokens.BADGE_DISC
	if column < 0 or row < 0 or column >= width or row >= disc:
		return false
	var radius: float = disc / 2.0
	var x: float = column + 0.5
	# Columns of the straight middle measure from the disc's centre.
	x = minf(x, radius) if x < width - radius else x - (width - disc)
	return Vector2(x - radius, row + 0.5 - radius).length_squared() <= radius * radius


func _ready() -> void:
	_update()


## The text the badge shows now.
func text() -> String:
	return label_for(kind, count)


## The drawn badge in the control's coordinates; a pill reaches left of the control.
func drawn_rect() -> Rect2:
	var art := float(NdosTokens.ART_PIXEL)
	var width: int = width_for(text(), glyphs)
	return Rect2((NdosTokens.BADGE_DISC - width) * art, 0.0, width * art, NdosTokens.BADGE_DISC * art)


func _update() -> void:
	if not is_node_ready():
		return
	custom_minimum_size = Vector2(NdosTokens.BADGE_DISC, NdosTokens.BADGE_DISC) * NdosTokens.ART_PIXEL
	size = custom_minimum_size
	_padlock.visible = kind == Kind.LOCK
	# The padlock centres on the disc at whole art pixels.
	var room: Vector2 = size - _padlock.size
	_padlock.position = (room / (2.0 * NdosTokens.ART_PIXEL)).floor() * NdosTokens.ART_PIXEL
	queue_redraw()


func _draw() -> void:
	var art := float(NdosTokens.ART_PIXEL)
	var label: String = text()
	var width: int = width_for(label, glyphs)
	var origin := Vector2(drawn_rect().position.x, 0.0)
	var colors: PackedColorArray = colors_for(kind)
	var fill: Color = colors[0]
	var rim: Color = colors[1]
	var ink: Color = colors[2]
	var rows: PackedStringArray = shape(width)
	for row: int in rows.size():
		for column: int in rows[row].length():
			var pixel: String = rows[row][column]
			if pixel != OUTSIDE:
				draw_rect(Rect2(origin + Vector2(column, row) * art, Vector2(art, art)), rim if pixel == RIM else fill)
	var corner: Vector2i = text_corner(label, glyphs, width)
	for pixel: Vector2i in glyphs.lit_pixels(label, NdosTokens.BADGE_GLYPH_GAP):
		draw_rect(Rect2(origin + Vector2(corner + pixel) * art, Vector2(art, art)), ink)
