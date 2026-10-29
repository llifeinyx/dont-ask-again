extends TestCase
## assets/ndos/theme.tres must be what tools/ndos/build_theme.gd makes from NdosTokens today.


func test_saved_theme_matches_the_tokens() -> void:
	var saved: Theme = load(NdosThemeBuilder.THEME_PATH)
	var built: Theme = NdosThemeBuilder.build()
	var hint: String = "rebuild it: godot --headless --path . --script res://tools/ndos/build_theme.gd"
	check(_same(saved.default_font, built.default_font), "default font; " + hint)
	check_eq(saved.default_font_size, built.default_font_size, "default font size; " + hint)
	for index: int in Theme.DATA_TYPE_MAX:
		var data_type := index as Theme.DataType
		var types: PackedStringArray = built.get_type_list()
		types.append_array(saved.get_type_list())
		for type_name: String in types:
			var names: PackedStringArray = built.get_theme_item_list(data_type, type_name)
			names.append_array(saved.get_theme_item_list(data_type, type_name))
			for item: String in names:
				var a: Variant = saved.get_theme_item(data_type, item, type_name)
				var b: Variant = built.get_theme_item(data_type, item, type_name)
				check(_same(a, b), "%s/%s differs; %s" % [type_name, item, hint])
	for base: StringName in [&"Label", &"Panel", &"PanelContainer", &"HBoxContainer", &"VBoxContainer"]:
		var saved_variations: PackedStringArray = saved.get_type_variation_list(base)
		var built_variations: PackedStringArray = built.get_type_variation_list(base)
		saved_variations.sort()
		built_variations.sort()
		check_eq(saved_variations, built_variations, "variations of %s; %s" % [base, hint])


## Equal values; resources are equal when every stored property is, or when they are the same file.
func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	if a is Resource:
		var ra: Resource = a
		var rb: Resource = b
		if rb == null or ra.get_class() != rb.get_class():
			return false
		if not ra.resource_path.is_empty() and not ra.resource_path.contains("::"):
			return ra.resource_path == rb.resource_path
		for property: Dictionary in ra.get_property_list():
			var usage: int = property["usage"]
			var property_name: String = property["name"]
			if usage & PROPERTY_USAGE_STORAGE and property_name != "resource_name":
				if not _same(ra.get(property_name), rb.get(property_name)):
					return false
		return true
	if a is Image:
		return true
	return a == b
