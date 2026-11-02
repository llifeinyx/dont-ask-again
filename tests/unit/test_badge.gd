extends TestCase
## The launcher badge is pixel art on ND-OS's art grid, whole and unclipped, for any count.

const DIGITS := "0123456789"
## Counts of one, two and three digits, and one past the largest the badge shows.
const COUNTS: Array[int] = [1, 3, 8, 12, 99, 100, 150]


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


func test_shape_holds_the_text_centred() -> void:
	var glyphs := _glyphs()
	for count: int in COUNTS:
		var text: String = LauncherBadge.label_for(LauncherBadge.Kind.COUNT, count)
		var text_width: int = glyphs.text_width(text, NdosTokens.BADGE_GLYPH_GAP)
		var width: int = LauncherBadge.width_for(text_width)
		check(width >= NdosTokens.BADGE_DISC, "%s: never narrower than the disc" % text)
		check_eq((width - text_width) % 2, 0, "%s: centred on whole art pixels" % text)
		var rows: PackedStringArray = LauncherBadge.shape(width)
		check_eq(rows.size(), NdosTokens.BADGE_DISC, "%s: the disc's height" % text)
		var left: int = floori((width - text_width) / 2.0)
		var top: int = floori((NdosTokens.BADGE_DISC - glyphs.height()) / 2.0)
		for pixel: Vector2i in glyphs.lit_pixels(text, NdosTokens.BADGE_GLYPH_GAP):
			var at: Vector2i = pixel + Vector2i(left, top)
			check_eq(rows[at.y][at.x], LauncherBadge.FILL, "%s: glyph pixel %s lies on the fill" % [text, at])
		for row: String in rows:
			check_eq(row, row.reverse(), "%s: the shape is symmetric" % text)


func test_shape_is_a_disc_with_a_rim() -> void:
	var rows: PackedStringArray = LauncherBadge.shape(NdosTokens.BADGE_DISC)
	var middle: int = floori(NdosTokens.BADGE_DISC / 2.0)
	check_eq(rows[middle][0], LauncherBadge.RIM, "rim on the left edge")
	check_eq(rows[0][middle], LauncherBadge.RIM, "rim on the top edge")
	check_eq(rows[0][0], LauncherBadge.OUTSIDE, "round corners")
	check_eq(rows[middle][middle], LauncherBadge.FILL, "filled centre")
	for row: int in rows.size():
		check_eq(rows[row], rows[rows.size() - 1 - row], "the disc is symmetric top to bottom")


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
