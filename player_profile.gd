extends ColorRect

const SocialCharacters := preload("res://social_characters.gd")
const INK := Color("4a354d")
const MUTED := Color("766079")
const PROFILE_CHARACTERS := [SocialCharacters.YUE, SocialCharacters.FUSHIMI, SocialCharacters.SHIRAKAWA]

var name_label: Label
var stats_label: Label
var resources_label: Label
var empty_affection_label: Label
var affection_rows: Dictionary[String, HBoxContainer] = {}
var affection_labels: Dictionary[String, Label] = {}


func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 620
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff4e8")
	paper.set_corner_radius_all(20)
	paper.shadow_color = Color(0.08, 0.04, 0.12, 0.35)
	paper.shadow_size = 16
	paper.content_margin_left = 28
	paper.content_margin_right = 28
	paper.content_margin_top = 20
	paper.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", paper)
	center.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	panel.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)
	var title := add_label(header, "个人信息", 26)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var back := Button.new()
	back.text = "返回手机"
	back.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back.pressed.connect(hide)
	header.add_child(back)

	name_label = add_label(content, "", 24)
	var attributes := HBoxContainer.new()
	content.add_child(attributes)
	stats_label = add_label(attributes, "", 19)
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resources_label = add_label(attributes, "", 19)

	content.add_child(HSeparator.new())
	add_label(content, "角色好感", 22)
	empty_affection_label = add_label(content, "还没有遇见可查看好感的角色。", 16)
	empty_affection_label.add_theme_color_override("font_color", MUTED)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	grid.add_theme_constant_override("v_separation", 12)
	content.add_child(grid)
	for character: String in PROFILE_CHARACTERS:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		grid.add_child(row)
		affection_rows[character] = row
		var avatar := TextureRect.new()
		avatar.texture = SocialCharacters.avatar(character)
		avatar.custom_minimum_size = Vector2(50, 50)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(avatar)
		var details := VBoxContainer.new()
		row.add_child(details)
		add_label(details, character, 19)
		var value := add_label(details, "", 16)
		value.add_theme_color_override("font_color", MUTED)
		affection_labels[character] = value

	visibility_changed.connect(refresh)
	PlayerState.changed.connect(refresh)


func add_label(parent: Control, caption: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = caption
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func refresh() -> void:
	if not is_visible_in_tree():
		return
	name_label.text = "%s  ·  %d 岁" % [PlayerState.player_name, PlayerState.get_age_years()]
	var stats := PackedStringArray()
	for index in PlayerState.STAT_NAMES.size():
		var progress := PlayerState.stat_progress(index)
		stats.append("%s  Lv.%d  ·  %d/%d" % [
			PlayerState.STAT_NAMES[index], progress.x, progress.y,
			PlayerState.stat_experience_required(progress.x)
		])
	stats_label.text = "\n".join(stats)
	resources_label.text = "金钱  %d 金\n精力  %s\n心态上限  %d\n升级点  %d" % [
		PlayerState.money, PlayerState.energy_text(), PlayerState.max_health, PlayerState.upgrade_points
	]
	var known := PlayerState.known_social_characters()
	var has_visible_character := false
	for character in PROFILE_CHARACTERS:
		var met: bool = PlayerState.high_school_intro_seen or character in known
		affection_rows[character].visible = met
		if not met:
			continue
		has_visible_character = true
		var progress := PlayerState.affection_progress(character)
		affection_labels[character].text = "Lv.%d  ·  %d/%d" % [
			progress.x, progress.y, PlayerState.AFFECTION_PER_LEVEL
		]
	empty_affection_label.visible = not has_visible_character
