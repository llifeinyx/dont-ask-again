class_name NdosMockup
extends RefCounted
## The state the Figma Desktop frame shows: ObServer active, badges 3, "!" and 6, the clock stopped at
## "10/17  9:00 AM". Screenshots set it through the Desktop's public API.

const MONTH: int = 10
const DAY: int = 17
const HOUR: int = 9
const CORPS_REQUESTS: int = 3
const HUMANET_MESSAGES: int = 6


static func apply(desktop: NdosDesktop) -> void:
	var clock := ClockSettings.new()
	clock.start_month = MONTH
	clock.start_day = DAY
	clock.start_hour = HOUR
	# Time stands still.
	desktop.clock.process_mode = Node.PROCESS_MODE_DISABLED
	desktop.clock.settings = clock
	desktop.clock.elapsed = 0.0
	desktop.select(NdosDesktop.Program.OBSERVER)
	desktop.set_badge(NdosDesktop.Program.CORPS, CORPS_REQUESTS)
	desktop.set_alert(NdosDesktop.Program.OBSERVER, true)
	desktop.set_badge(NdosDesktop.Program.HUMANET, HUMANET_MESSAGES)
