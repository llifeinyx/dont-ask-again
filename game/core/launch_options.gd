class_name LaunchOptions
extends RefCounted
## Flags given after "--" on the command line.
##   --windowed      start in a window instead of fullscreen
##   --frames=N      quit after N frames (smoke tests)
##   --shots=<dir>   save screenshots of fixed states into <dir>, then quit

var windowed: bool = false
var quit_after_frames: int = 0
var shots_dir: String = ""
var unknown: PackedStringArray = []


static func parse(args: PackedStringArray) -> LaunchOptions:
	var options := LaunchOptions.new()
	for arg: String in args:
		if arg == "--windowed":
			options.windowed = true
		elif arg.begins_with("--frames="):
			options.quit_after_frames = maxi(0, arg.trim_prefix("--frames=").to_int())
		elif arg.begins_with("--shots="):
			options.shots_dir = arg.trim_prefix("--shots=")
		else:
			options.unknown.append(arg)
	return options


static func current() -> LaunchOptions:
	return parse(OS.get_cmdline_user_args())
