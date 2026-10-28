extends TestCase


func test_defaults() -> void:
	var options := LaunchOptions.parse(PackedStringArray())
	check_eq(options.windowed, false, "windowed")
	check_eq(options.quit_after_frames, 0, "frames")
	check_eq(options.shots_dir, "", "shots")
	check(options.unknown.is_empty(), "no unknown flags")


func test_all_flags() -> void:
	var options := LaunchOptions.parse(PackedStringArray(["--windowed", "--frames=30", "--shots=/tmp/shots"]))
	check_eq(options.windowed, true, "windowed")
	check_eq(options.quit_after_frames, 30, "frames")
	check_eq(options.shots_dir, "/tmp/shots", "shots")


func test_bad_values_are_safe() -> void:
	var options := LaunchOptions.parse(PackedStringArray(["--frames=-5", "--frames", "--fullscreen"]))
	check_eq(options.quit_after_frames, 0, "negative frames clamp to zero")
	check_eq(options.unknown, PackedStringArray(["--frames", "--fullscreen"]), "unknown flags are kept for a warning")
