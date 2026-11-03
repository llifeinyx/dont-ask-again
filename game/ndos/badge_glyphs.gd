class_name BadgeGlyphs
extends Resource
## The badge's own pixel digits, drawn on ND-OS's art grid: each glyph is rows of "#" (lit) and "."
## (clear), one character per art pixel. game/ndos/badge_glyphs.tres holds the set.

const LIT := "#"
const CLEAR := "."

## Glyph rows by character, all the same height.
@export var glyphs: Dictionary[String, PackedStringArray] = {}


## Height of every glyph, in art pixels.
func height() -> int:
	if glyphs.is_empty():
		return 0
	var first: PackedStringArray = glyphs.values()[0]
	return first.size()


## Width of a glyph, in art pixels.
func width_of(character: String) -> int:
	return glyphs[character][0].length()


## Width of a text with gap art pixels between its glyphs.
func text_width(text: String, gap: int) -> int:
	var total: int = 0
	for character: String in text:
		total += width_of(character)
	return total + gap * maxi(text.length() - 1, 0)


## The lit art pixels of a text, from its top-left corner, glyphs gap art pixels apart.
func lit_pixels(text: String, gap: int) -> Array[Vector2i]:
	var lit: Array[Vector2i] = []
	var x: int = 0
	for character: String in text:
		var rows: PackedStringArray = glyphs[character]
		for y: int in rows.size():
			for column: int in rows[y].length():
				if rows[y][column] == LIT:
					lit.append(Vector2i(x + column, y))
		x += width_of(character) + gap
	return lit
