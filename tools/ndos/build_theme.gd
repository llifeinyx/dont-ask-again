extends SceneTree
## Writes assets/ndos/theme.tres from NdosTokens. Run it after changing a token, then commit both:
##   godot --headless --path . --script res://tools/ndos/build_theme.gd


func _init() -> void:
	var error: Error = ResourceSaver.save(NdosThemeBuilder.build(), NdosThemeBuilder.THEME_PATH)
	if error != OK:
		push_error("Could not save %s: %s" % [NdosThemeBuilder.THEME_PATH, error_string(error)])
	quit(0 if error == OK else 1)
