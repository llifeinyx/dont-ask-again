extends TestCase
## The launcher badge is pixel art on ND-OS's art grid, whole and unclipped, for any count.

const DIGITS := "0123456789"
## Counts of one, two and three digits, and one past the largest the badge shows.
const COUNTS: Array[int] = [1, 3, 8, 12, 25, 77, 99, 100, 150]
## The 13-art-pixel disc as drawn: R rim, F fill.
const DISC: Array[String] = [
	"....RRRRR....",
	"..RRFFFFFRR..",
	".RFFFFFFFFFR.",
	".RFFFFFFFFFR.",
	"RFFFFFFFFFFFR",
	"RFFFFFFFFFFFR",
	"RFFFFFFFFFFFR",
	"RFFFFFFFFFFFR",
	"RFFFFFFFFFFFR",
	".RFFFFFFFFFR.",
	".RFFFFFFFFFR.",
	"..RRFFFFFRR..",
	"....RRRRR....",
]


func _glyphs() -> BadgeGlyphs:
	return load("res://game/ndos/badge_glyphs.tres")


func test_glyphs_are_whole_art_pixel_rows() -> void:
	var glyphs := _glyphs()
	var characters: String = DIGITS + NdosTokens.BADGE_OVERFLOW + NdosTokens.BADGE_ALERT
	check_eq(glyphs.glyphs.size(), characters.length(), "a glyph for every digit, the overflow and the alert")
	for character: String in characters:
		check(glyphs.glyphs.has(character), "a glyph for %s" % character)
		var rows: PackedStringArray = glyphs.glyphs.get(character, PackedStringArray())
		check_eq(rows.size(), glyphs.height(), "%s has the common height" % character)
		check(glyphs.height() % 2 == NdosTokens.BADGE_DISC % 2, "glyph and disc heights centre together")
		for row: String in rows:
			check_eq(row.length(), glyphs.width_of(character), "%s rows are one width" % character)
			check(row.replace(BadgeGlyphs.LIT, "").replace(BadgeGlyphs.CLEAR, "").is_empty(),
				"%s uses only lit and clear pixels: %s" % [character, row])


func test_labels() -> void:
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, 3), "3", "one digit")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, 12), "12", "two digits")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, NdosTokens.BADGE_MAX_COUNT), "99", "the largest")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, 100), "99+", "100 overflows")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, 150), "99+", "150 overflows")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.ALERT, 5), "!", "the alert ignores the count")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.LOCK, 5), "", "the padlock has no text")
	check_eq(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, -2), "0", "never a glyph that does not exist")


func test_shape_holds_the_text_centred_and_clear_of_the_rim() -> void:
	var glyphs := _glyphs()
	var texts: Array[String] = [NdosTokens.BADGE_ALERT]
	for count: int in COUNTS:
		texts.append(LauncherBadge.label_for(LauncherBadge.Kind.COUNT, count))
	for text: String in texts:
		var text_width: int = glyphs.text_width(text, NdosTokens.BADGE_GLYPH_GAP)
		var width: int = LauncherBadge.width_for(text, glyphs)
		check(width >= NdosTokens.BADGE_DISC, "%s: never narrower than the disc" % text)
		check_eq((width - text_width) % 2, 0, "%s: centred on whole art pixels" % text)
		var rows: PackedStringArray = LauncherBadge.shape(width)
		check_eq(rows.size(), NdosTokens.BADGE_DISC, "%s: the disc's height" % text)
		var corner: Vector2i = LauncherBadge.text_corner(text, glyphs, width)
		var reach: int = NdosTokens.BADGE_PILL_PADDING
		for pixel: Vector2i in glyphs.lit_pixels(text, NdosTokens.BADGE_GLYPH_GAP):
			for dy: int in range(-reach, reach + 1):
				for dx: int in range(-reach, reach + 1):
					var at: Vector2i = corner + pixel + Vector2i(dx, dy)
					check(at.y >= 0 and at.y < rows.size() and at.x >= 0 and at.x < width
						and rows[at.y][at.x] == LauncherBadge.FILL,
						"%s: fill around glyph pixel %s at %s" % [text, pixel, at])
		for row: String in rows:
			check_eq(row, row.reverse(), "%s: the shape is symmetric" % text)
	check_eq(LauncherBadge.width_for("3", glyphs), NdosTokens.BADGE_DISC, "one digit fits the disc")
	check_eq(LauncherBadge.width_for("", glyphs), NdosTokens.BADGE_DISC, "the padlock badge is the disc")


func test_shape_is_the_disc_with_a_one_pixel_rim() -> void:
	var rows: PackedStringArray = LauncherBadge.shape(NdosTokens.BADGE_DISC)
	check_eq(Array(rows), DISC, "the disc")
	for width: int in [NdosTokens.BADGE_DISC, NdosTokens.BADGE_DISC + 4, NdosTokens.BADGE_DISC + 10]:
		var shape: PackedStringArray = LauncherBadge.shape(width)
		for y: int in shape.size():
			for x: int in width:
				if shape[y][x] == LauncherBadge.OUTSIDE:
					continue
				var touches_outside: bool = false
				for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var at: Vector2i = Vector2i(x, y) + step
					touches_outside = touches_outside or at.x < 0 or at.y < 0 or at.x >= width \
						or at.y >= shape.size() or shape[at.y][at.x] == LauncherBadge.OUTSIDE
				check_eq(shape[y][x] == LauncherBadge.RIM, touches_outside,
					"width %d, %s: rim exactly where the shape meets the outside" % [width, Vector2i(x, y)])


func test_colours() -> void:
	check_eq(LauncherBadge.colors_for(LauncherBadge.Kind.COUNT),
		PackedColorArray([NdosTokens.BADGE_BG, NdosTokens.BADGE_LINE, NdosTokens.DARK]), "count: fill, rim, ink")
	check_eq(LauncherBadge.colors_for(LauncherBadge.Kind.ALERT),
		PackedColorArray([NdosTokens.BADGE_RED, NdosTokens.BADGE_BG, NdosTokens.PANEL_TEXT]), "alert: fill, rim, ink")


func test_badges_sit_on_the_art_grid_unclipped() -> void:
	var desktop: NdosDesktop = (load("res://game/ndos/desktop.tscn") as PackedScene).instantiate()
	var tree: SceneTree = Engine.get_main_loop()
	tree.root.add_child(desktop)
	# Containers lay out on a deferred call; do it now, parents first.
	for node: Node in [desktop] + desktop.find_children("*", "Container", true, false):
		node.notification(Container.NOTIFICATION_SORT_CHILDREN)
	var screen := Rect2(Vector2.ZERO, Vector2(NdosTokens.SCREEN_SIZE))
	var art := float(NdosTokens.ART_PIXEL)
	var badges: Array[Node] = desktop.find_children("*", "LauncherBadge", true, false)
	# A count badge and a padlock badge on every program's slot.
	check_eq(badges.size(), 2 * (NdosDesktop.Program.size() - 1), "every slot's badges")
	for node: Node in badges:
		var badge: LauncherBadge = node
		for count: int in COUNTS:
			badge.count = count
			var corner: Vector2 = badge.global_position - desktop.global_position + badge.drawn_rect().position
			var drawn := Rect2(corner, badge.drawn_rect().size)
			var where: String = "%s at %d" % [desktop.get_path_to(badge), count]
			check(fmod(drawn.position.x, art) == 0.0 and fmod(drawn.position.y, art) == 0.0,
				"%s: drawn from %s, on the art grid" % [where, drawn.position])
			check(screen.encloses(drawn), "%s: %s inside ND-OS" % [where, drawn])
		var ancestor: Node = badge.get_parent()
		while ancestor != desktop.get_parent():
			var control := ancestor as Control
			check(control == null or not control.clip_contents,
				"%s: %s does not clip it" % [desktop.get_path_to(badge), ancestor.name])
			ancestor = ancestor.get_parent()
	desktop.free()
