extends TestCase


func _samples(pattern: FlickerPattern) -> PackedFloat32Array:
	var values := PackedFloat32Array()
	for i: int in 2000:
		values.append(pattern.sample(i * 0.013))
	return values


func test_stays_in_range() -> void:
	for value: float in _samples(FlickerPattern.new()):
		check(value >= 0.0 and value <= 1.0, "sample %f out of range" % value)


func test_is_repeatable() -> void:
	check_eq(_samples(FlickerPattern.new()), _samples(FlickerPattern.new()), "same seed, same flicker")
	var other := FlickerPattern.new()
	other.noise_seed = 2
	check(_samples(other) != _samples(FlickerPattern.new()), "another seed flickers differently")


func test_without_dips_only_wavers() -> void:
	var pattern := FlickerPattern.new()
	pattern.dip_chance = 0.0
	for value: float in _samples(pattern):
		check(value >= 1.0 - pattern.waver_depth - 0.0001, "no dip below the waver: %f" % value)


func test_dip_reaches_its_level() -> void:
	var pattern := FlickerPattern.new()
	pattern.dip_chance = 1.0
	pattern.waver_depth = 0.0
	check(is_equal_approx(pattern.sample(pattern.dip_length * 0.5), pattern.dip_level), "bottom of a dip")
	check(is_equal_approx(pattern.sample(0.0), 1.0), "a dip starts from full brightness")
