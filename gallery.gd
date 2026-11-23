@tool
extends Control

const CHARACTER_DIRECTORY := "res://images/character"
const FRAME_TEXTURE := preload("res://images/gallery_frame.png")
const PAPER_TEXTURE := preload("res://images/settings_letter.png")
const CARD_SIZE := Vector2(270.0, 315.0)

@onready var deck: Control = $PhotoDeck
@onready var sleeves: Control = $PhotoDeck/Sleeves
@onready var gallery_music: AudioStreamPlayer = $GalleryMusic
@onready var back_button: Button = $BackButton
@onready var count_label: Label = $CountLabel
@onready var preview: Control = $Preview
@onready var preview_art: TextureRect = $Preview/Art
@onready var previous_button: Button = $Preview/PreviousButton
@onready var next_button: Button = $Preview/NextButton
@onready var close_button: Button = $Preview/CloseButton

var image_paths: Array[String] = []
var card_visuals: Array[Control] = []
var card_tweens: Array[Tween] = []
var selected_index := 0
var preview_index := 0


func _ready() -> void:
	load_character_images()
	build_sleeves()
	build_cards()
	layout_cards(false)
	if Engine.is_editor_hint():
		return
	var music_stream := gallery_music.stream.duplicate() as AudioStreamMP3
	music_stream.loop = true
	gallery_music.stream = music_stream
	gallery_music.play()
	back_button.pressed.connect(close_gallery)
	close_button.pressed.connect(func() -> void: preview.hide())
	previous_button.pressed.connect(func() -> void: change_preview(-1))
	next_button.pressed.connect(func() -> void: change_preview(1))
	animate_cards()


func load_character_images() -> void:
	var files := DirAccess.get_files_at(CHARACTER_DIRECTORY)
	files.sort()
	for file in files:
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
			image_paths.append(CHARACTER_DIRECTORY.path_join(file))
	update_count_label()


func build_sleeves() -> void:
	var deck_width := deck.size.x if deck.size.x > 0.0 else 1152.0
	var sleeve_count := ceili(deck_width / 108.0) + 3
	for row_index in 2:
		for index in sleeve_count:
			var sleeve := make_texture_rect(PAPER_TEXTURE, Vector2(index * 108.0 - 80.0 + row_index * 45.0, 310.0 + row_index * 105.0 + 8.0 * sin(index * 0.8)), Vector2(185.0, 275.0), TextureRect.STRETCH_SCALE)
			sleeve.rotation = -0.045
			sleeve.modulate = Color(1.0, 0.96, 0.88, 0.55 if row_index == 0 else 0.73)
			sleeves.add_child(sleeve)


func build_cards() -> void:
	if image_paths.is_empty():
		count_label.text = "角色图片文件夹目前是空的"
		return
	for index in image_paths.size():
		var card := make_card(index)
		deck.add_child(card)


func make_card(index: int) -> Control:
	var visual := Control.new()
	visual.set_size(CARD_SIZE)
	visual.pivot_offset = Vector2(135.0, 285.0)
	visual.mouse_filter = Control.MOUSE_FILTER_STOP
	visual.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	visual.gui_input.connect(on_card_input.bind(index))
	card_visuals.append(visual)

	var backing := ColorRect.new()
	backing.color = Color(0.996, 0.954, 0.883)
	backing.position = Vector2(21.0, 21.0)
	backing.size = Vector2(228.0, 220.0)
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(backing)
	var paper := make_texture_rect(PAPER_TEXTURE, Vector2(20.0, 20.0), Vector2(230.0, 223.0), TextureRect.STRETCH_SCALE)
	visual.add_child(paper)
	var art := make_texture_rect(load(image_paths[index]) as Texture2D, Vector2(32.0, 32.0), Vector2(205.0, 194.0), TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	visual.add_child(art)
	var frame := make_texture_rect(FRAME_TEXTURE, Vector2.ZERO, Vector2(270.0, 309.0), TextureRect.STRETCH_SCALE)
	visual.add_child(frame)

	var caption := Label.new()
	caption.position = Vector2(27.0, 244.0)
	caption.size = Vector2(216.0, 38.0)
	caption.text = image_paths[index].get_file().get_basename().replace("_", " ")
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_color_override("font_color", Color(0.27, 0.23, 0.27))
	caption.add_theme_font_size_override("font_size", 17)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visual.add_child(caption)
	return visual


func make_texture_rect(texture: Texture2D, at: Vector2, dimensions: Vector2, mode: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = mode
	rect.position = at
	rect.size = dimensions
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func animate_cards() -> void:
	for index in card_visuals.size():
		var card := card_visuals[index]
		var final_y := card.position.y
		card.position.y += size.y + 110.0
		var tween := create_tween()
		tween.tween_property(card, "position:y", final_y, 1.35).set_delay(index * 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		card_tweens.append(tween)


func layout_cards(animated: bool) -> void:
	if image_paths.is_empty():
		return
	if animated:
		for tween in card_tweens:
			if tween.is_running():
				tween.kill()
		card_tweens.clear()
	var deck_width := deck.size.x if deck.size.x > 0.0 else 1152.0
	var center_x := (deck_width - CARD_SIZE.x) * 0.5
	var count := image_paths.size()
	for index in count:
		var forward := posmod(index - selected_index, count)
		var backward := forward - count
		var relative := forward if absi(forward) <= absi(backward) else backward
		var distance := absi(relative)
		var target_position := Vector2(center_x + relative * 305.0, 35.0 if distance == 0 else 245.0 + (distance - 1) * 36.0)
		var target_scale := Vector2.ONE * (1.10 if distance == 0 else maxf(0.62, 0.87 - (distance - 1) * 0.08))
		var target_rotation := 0.0 if distance == 0 else signf(relative) * 0.065
		var target_color := Color(1.0, 1.0, 1.0, 1.0 if distance < 3 else 0.0)
		var card := card_visuals[index]
		card.z_index = 20 - distance
		if animated:
			var tween := create_tween().set_parallel(true)
			tween.tween_property(card, "position", target_position, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(card, "scale", target_scale, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(card, "rotation", target_rotation, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(card, "modulate", target_color, 0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			card_tweens.append(tween)
		else:
			card.position = target_position
			card.scale = target_scale
			card.rotation = target_rotation
			card.modulate = target_color
	update_count_label()


func select_photo(direction: int) -> void:
	if image_paths.is_empty():
		return
	selected_index = posmod(selected_index + direction, image_paths.size())
	layout_cards(true)


func select_photo_to(index: int) -> void:
	if selected_index != index:
		selected_index = index
		layout_cards(true)


func update_count_label() -> void:
	if image_paths.is_empty():
		return
	var name := image_paths[selected_index].get_file().get_basename().replace("_", " ")
	count_label.text = "%d / %d  ·  %s  ·  滚轮切换，点击照片查看" % [selected_index + 1, image_paths.size(), name]


func on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		show_preview(index)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or image_paths.is_empty() or not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if preview.visible:
			change_preview(-1)
		else:
			select_photo(-1)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if preview.visible:
			change_preview(1)
		else:
			select_photo(1)
		get_viewport().set_input_as_handled()


func show_preview(index: int) -> void:
	preview_index = posmod(index, image_paths.size())
	select_photo_to(preview_index)
	preview_art.texture = load(image_paths[preview_index]) as Texture2D
	preview.show()


func change_preview(direction: int) -> void:
	show_preview(preview_index + direction)


func close_gallery() -> void:
	SceneFade.play_action(queue_free)


func set_return_to_bedroom() -> void:
	$BackButton.text = "← 返回卧室"


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			if preview.visible:
				preview.hide()
			else:
				close_gallery()
		KEY_LEFT:
			get_viewport().set_input_as_handled()
			if preview.visible:
				change_preview(-1)
			else:
				select_photo(-1)
		KEY_RIGHT:
			get_viewport().set_input_as_handled()
			if preview.visible:
				change_preview(1)
			else:
				select_photo(1)
