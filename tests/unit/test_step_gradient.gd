extends TestCase

## Rows of the top panel in Figma's export of the Desktop frame (most common colour of each row).
const FIGMA_ROWS: Array[Color] = [
	Color8(112, 104, 90), Color8(112, 104, 90), Color8(112, 104, 90), Color8(112, 104, 90),
	Color8(111, 103, 89), Color8(109, 101, 87), Color8(109, 101, 87), Color8(109, 101, 87),
	Color8(109, 101, 87), Color8(107, 99, 86), Color8(106, 98, 85), Color8(106, 98, 85),
	Color8(106, 98, 85), Color8(106, 98, 85), Color8(103, 95, 82), Color8(103, 95, 82),
	Color8(103, 95, 82), Color8(103, 95, 82), Color8(103, 95, 82), Color8(99, 92, 79),
	Color8(99, 92, 79), Color8(99, 92, 79), Color8(99, 92, 79), Color8(98, 91, 78),
	Color8(96, 89, 76), Color8(96, 89, 76), Color8(96, 89, 76), Color8(96, 89, 76),
	Color8(94, 87, 75), Color8(93, 86, 74), Color8(93, 86, 74), Color8(93, 86, 74),
	Color8(93, 86, 74), Color8(91, 83, 71), Color8(90, 83, 71), Color8(90, 83, 71),
	Color8(90, 83, 71), Color8(90, 83, 71),
]
## Figma's own rounding of a mixed row differs from ours by up to one step.
const TOLERANCE: int = 1


func test_top_panel_matches_figma() -> void:
	var rows: PackedColorArray = StepGradient.rows(NdosTokens.TOP_PANEL_STEPS, NdosTokens.TOP_PANEL_HEIGHT)
	check_eq(rows.size(), FIGMA_ROWS.size(), "row count")
	for y: int in mini(rows.size(), FIGMA_ROWS.size()):
		var ours: Color = rows[y]
		var figma: Color = FIGMA_ROWS[y]
		var off: int = maxi(absi(ours.r8 - figma.r8), maxi(absi(ours.g8 - figma.g8), absi(ours.b8 - figma.b8)))
		check(off <= TOLERANCE, "row %d: %s, Figma has %s" % [y, ours.to_html(false), figma.to_html(false)])


func test_whole_rows_keep_their_step() -> void:
	var steps: Array[Color] = [Color.RED, Color.BLUE]
	var rows: PackedColorArray = StepGradient.rows(steps, 4)
	check_eq(rows, PackedColorArray([Color.RED, Color.RED, Color.BLUE, Color.BLUE]), "two steps over four rows")


func test_boundary_row_mixes_by_coverage() -> void:
	var steps: Array[Color] = [Color.BLACK, Color.WHITE]
	var rows: PackedColorArray = StepGradient.rows(steps, 3)
	check(rows[1].is_equal_approx(Color(0.5, 0.5, 0.5)), "the middle row is half black, half white")
	check(rows[0].is_equal_approx(Color.BLACK) and rows[2].is_equal_approx(Color.WHITE), "outer rows stay pure")
