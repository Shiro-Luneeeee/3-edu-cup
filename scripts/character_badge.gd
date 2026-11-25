extends Button


func configure(avatar: Texture2D, hint: String, diameter: float, story_available: bool = false) -> void:
	custom_minimum_size = Vector2.ONE * diameter
	tooltip_text = hint
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var radius := roundi(diameter * 0.5)
	add_theme_stylebox_override("normal", make_style(Color("fff0df"), Color("a67dac"), radius))
	add_theme_stylebox_override("hover", make_style(Color("fff8ee"), Color("cd87a2"), radius))
	add_theme_stylebox_override("pressed", make_style(Color("ead6eb"), Color("9f689b"), radius))
	var artwork := TextureRect.new()
	artwork.texture = avatar
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var inset := diameter * 0.10
	artwork.offset_left = inset
	artwork.offset_right = -inset
	artwork.offset_top = inset
	artwork.offset_bottom = -inset
	if story_available:
		tooltip_text += " · 有新剧情"
		add_story_dot(diameter)


func add_story_dot(diameter: float) -> void:
	var dot := Panel.new()
	dot.name = "StoryDot"
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.size = Vector2.ONE * roundf(diameter * 0.21)
	dot.position = Vector2.ONE * roundf(diameter * 0.035)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dd415b")
	style.border_color = Color("fff4e7")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	dot.add_theme_stylebox_override("panel", style)
	add_child(dot)


func make_style(paper: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = paper
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.23, 0.12, 0.27, 0.34)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style
