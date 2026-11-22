extends "res://map_destination.gd"

const STORY_SCENE: PackedScene = preload("res://daoxiang_vn.tscn")
const PAPER: Texture2D = preload("res://images/aged_blank_a4_paper.png")

var note := TextureRect.new()
var title := Label.new()
var description := Label.new()
var walk_button := Button.new()
var back_button := Button.new()
var story: Control


func _ready() -> void:
	var fill := AtlasTexture.new()
	fill.atlas = PAPER
	fill.region = Rect2(PAPER.get_size() * Vector2(0.07, 0.06), PAPER.get_size() * Vector2(0.86, 0.87))
	note.texture = fill
	note.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	note.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(note)
	for item in [title, description, walk_button, back_button]:
		note.add_child(item)
		item.add_theme_color_override("font_color", Color("514d54"))
	title.text = "公园 · 散步"
	title.add_theme_font_size_override("font_size", 24)
	description.add_theme_font_size_override("font_size", 17)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for button in [walk_button, back_button]:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.add_theme_color_override("font_hover_color", Color("93704e"))
		button.add_theme_color_override("font_pressed_color", Color("514d54"))
		button.add_theme_font_size_override("font_size", 18)
	walk_button.text = "沿着小路散步  →"
	walk_button.pressed.connect(walk)
	back_button.text = "返回地图"
	back_button.pressed.connect(func() -> void: SceneFade.play_action(queue_free, -1.0))
	PlayerState.changed.connect(update_note)
	resized.connect(layout_note)
	layout_note()
	update_note()


func layout_note() -> void:
	var factor := minf(size.x / 1152.0, size.y / 648.0)
	note.size = Vector2(345, 250)
	note.scale = Vector2.ONE * factor
	note.position = Vector2(size.x - note.size.x * factor - 28 * factor, size.y - note.size.y * factor - 28 * factor)
	title.position = Vector2(27, 22)
	title.size = Vector2(290, 38)
	description.position = Vector2(27, 75)
	description.size = Vector2(290, 100)
	back_button.position = Vector2(24, 196)
	back_button.size = Vector2(110, 32)
	walk_button.position = Vector2(142, 192)
	walk_button.size = Vector2(180, 38)


func update_note() -> void:
	match PlayerState.available_daoxiang_act():
		1: description.text = "风从树下经过。\n也许会遇见一位写诗的女孩。"
		2: description.text = "中考后的夏天。\n河边似乎有人在等一场回答。"
		3: description.text = "稻香粽子 · 第三幕\n世界没有童话，我们还有彼此。"
		_:
			if PlayerState.daoxiang_act == 3:
				description.text = "那张旧纸条，仍被好好地收着。"
			elif PlayerState.daoxiang_act == 0 and PlayerState.get_age_years() > 14:
				description.text = "风经过长椅。\n有些相遇，已经错过了季节。"
			else:
				description.text = "今天的公园很安静。\n沿着小路走走吧。"


func walk() -> void:
	if is_instance_valid(story):
		return
	var next_act := PlayerState.available_daoxiang_act()
	if next_act == 0:
		description.text = "你沿着小路走了一圈。\n风从树叶间轻轻吹过。"
		return
	story = STORY_SCENE.instantiate() as Control
	story.set("act", next_act)
	add_child(story)
	story.tree_exited.connect(update_note)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(story):
		return
	super._unhandled_key_input(event)
