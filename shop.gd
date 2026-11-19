extends Control

const BOARD_SIZE := Vector2(1680.0, 941.0)
const BOARD_PATH := "res://images/shop_board.png"
const NOTE_PATH := "res://images/ui/note.png"
const BEDROOM_SCENE := "res://bedroom.tscn"
const CATEGORIES := ["推荐", "学习", "娱乐", "其他"]
const CATEGORY_ICONS := ["★", "▤", "♫", "···"]

var board: TextureRect
var page_layer: TextureRect
var category_buttons: Array[TextureButton] = []
var category_labels: Array[Label] = []
var category_icons: Array[Label] = []
var selected_index := 0
var layout_scale := 1.0
var layout_origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var board_texture := load_png_texture(BOARD_PATH)
	var note_texture := load_png_texture(NOTE_PATH)
	board = TextureRect.new()
	board.name = "ShopBoard"
	board.texture = board_texture
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)

	for index in CATEGORIES.size():
		var button := TextureButton.new()
		button.name = "Category%d" % index
		button.texture_normal = note_texture
		button.texture_hover = note_texture
		button.texture_pressed = note_texture
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(select_category.bind(index))
		button.z_index = 2
		add_child(button)

		var label := Label.new()
		label.name = "CategoryLabel"
		label.text = CATEGORIES[index]
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 38.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color("594375"))
		label.add_theme_color_override("font_outline_color", Color("fff0cc"))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override("font_size", 23)
		button.add_child(label)
		category_labels.append(label)

		var icon := Label.new()
		icon.name = "CategoryIcon"
		icon.text = CATEGORY_ICONS[index]
		icon.position = Vector2(16.0, 0.0)
		icon.size = Vector2(44.0, 78.0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_theme_color_override("font_color", Color("775b97"))
		icon.add_theme_color_override("font_outline_color", Color("fff0cc"))
		icon.add_theme_constant_override("outline_size", 2)
		icon.add_theme_font_size_override("font_size", 25)
		button.add_child(icon)
		category_icons.append(icon)
		category_buttons.append(button)

	# The page is layered over the category notes, with the purple base beneath both.
	var atlas := AtlasTexture.new()
	atlas.atlas = board_texture
	atlas.region = Rect2(262.0, 45.0, 1396.0, 810.0)
	page_layer = TextureRect.new()
	page_layer.name = "BookPageLayer"
	page_layer.texture = atlas
	page_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_layer.stretch_mode = TextureRect.STRETCH_SCALE
	page_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_layer.z_index = 3
	add_child(page_layer)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "×"
	back_button.flat = true
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.z_index = 10
	back_button.add_theme_color_override("font_color", Color("65487d"))
	back_button.add_theme_color_override("font_hover_color", Color("b95c68"))
	back_button.add_theme_font_size_override("font_size", 48)
	back_button.pressed.connect(SceneFade.change_to.bind(BEDROOM_SCENE, -1.0))
	add_child(back_button)

	resized.connect(update_layout)
	update_layout()
	select_category(0)


func load_png_texture(path: String) -> Texture2D:
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(image)


func update_layout() -> void:
	if board == null:
		return
	layout_scale = minf(size.x / BOARD_SIZE.x, size.y / BOARD_SIZE.y)
	layout_origin = (size - BOARD_SIZE * layout_scale) * 0.5
	board.position = layout_origin
	board.size = BOARD_SIZE * layout_scale
	for index in category_buttons.size():
		var button := category_buttons[index]
		button.position = layout_origin + Vector2(50.0, 194.0 + index * 145.0) * layout_scale
		button.size = Vector2(216.0, 78.0) * layout_scale
		category_labels[index].offset_left = 38.0 * layout_scale
		category_labels[index].add_theme_font_size_override("font_size", maxi(1, roundi(23.0 * layout_scale)))
		category_icons[index].position = Vector2(16.0, 0.0) * layout_scale
		category_icons[index].size = Vector2(44.0, 78.0) * layout_scale
		category_icons[index].add_theme_font_size_override("font_size", maxi(1, roundi(25.0 * layout_scale)))
	page_layer.position = layout_origin + Vector2(262.0, 45.0) * layout_scale
	page_layer.size = Vector2(1396.0, 810.0) * layout_scale
	var back_button := get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.position = layout_origin + Vector2(1580.0, 48.0) * layout_scale
		back_button.size = Vector2(58.0, 58.0) * layout_scale
		back_button.add_theme_font_size_override("font_size", maxi(1, roundi(48.0 * layout_scale)))


func select_category(index: int) -> void:
	selected_index = index
	for current_index in category_buttons.size():
		var button := category_buttons[current_index]
		var selected := current_index == selected_index
		button.z_index = 5 if selected else 2
		button.pivot_offset = button.size * 0.5
		var target_scale := Vector2.ONE * (1.14 if selected else 1.0)
		var target_modulate := Color(1.0, 0.88, 0.62, 1.0) if selected else Color(0.72, 0.70, 0.82, 1.0)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", target_scale, 0.16)
		tween.parallel().tween_property(button, "modulate", target_modulate, 0.16)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		SceneFade.change_to(BEDROOM_SCENE, -1.0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		SceneFade.change_to(BEDROOM_SCENE, -1.0)
		get_viewport().set_input_as_handled()
