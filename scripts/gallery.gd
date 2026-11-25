@tool
extends Control

const CHARACTER_DIRECTORY := "res://images/character"
const FRAME_TEXTURE := preload("res://images/gallery_frame.png")
const PAPER_TEXTURE := preload("res://images/settings_letter.png")
const CARD_SIZE := Vector2(270.0, 315.0)
const STORY_CG := [
	["summer_birth.png", "序章 · 夏日初生"],
	["park_meeting/ants.png", "初遇 · 蚂蚁的路"],
	["park_meeting/greeting.png", "初遇 · 你好呀"],
	["park_meeting/promise.png", "初遇 · 拉钩"],
	["yue_goldfish/bag.png", "阳奈里 · 小金鱼"],
	["yue_goldfish/gift.png", "阳奈里 · 礼物"],
	["yue_goldfish/sunset.png", "阳奈里 · 池边夕阳"],
	["yue_farewell/room.png", "阳奈里 · 鱼缸旁"],
	["yue_farewell/fishbowl.png", "阳奈里 · 告别"],
	["yue_farewell/closeup.png", "阳奈里 · 回望"],
	["yue_confession/smile.jpg", "阳奈里 · 重逢"],
	["yue_confession/pouting.png", "阳奈里 · 闹别扭"],
	["yue_confession/attentive.png", "阳奈里 · 倾听"],
	["yue_confession/surprised.jpg", "阳奈里 · 心动"],
	["yue_confession/shy.png", "阳奈里 · 害羞"],
	["yue_confession/reciprocal.png", "阳奈里 · 回应"],
	["yue_confession/playful.png", "阳奈里 · 笑意"],
	["yue_final_promise/worried.jpg", "阳奈里 · 忧虑"],
	["yue_final_promise/protest.jpg", "阳奈里 · 不许"],
	["yue_final_promise/relieved.jpg", "阳奈里 · 安心"],
	["yue_final_promise/teasing.jpg", "阳奈里 · 约定"],
	["fushimi_pen_story/stationery.png", "伏见宫 · 那支钢笔"],
	["fushimi_tutoring/quiz.png", "伏见宫 · 小测验"],
	["fushimi_tutoring/tutoring.png", "伏见宫 · 补习"],
	["fushimi_tutoring/farewell.png", "伏见宫 · 放学后"],
	["fushimi_bookshop/storefront.png", "伏见宫 · 旧书店"],
	["fushimi_bookshop/reading.png", "伏见宫 · 绘本"],
	["fushimi_bookshop/caught.png", "伏见宫 · 被发现"],
	["fushimi_bookshop/embarrassed.png", "伏见宫 · 脸红"],
	["fushimi_bookshop/smile.png", "伏见宫 · 微笑"],
	["fushimi_confession/hallway.png", "伏见宫 · 走廊"],
	["fushimi_confession/exam.png", "伏见宫 · 晚自习"],
	["fushimi_confession/listening.png", "伏见宫 · 心事"],
	["fushimi_confession/smile.png", "伏见宫 · 释然"],
	["fushimi_confession/surprised.png", "伏见宫 · 意外"],
	["fushimi_confession/path.png", "伏见宫 · 夜路"],
	["fushimi_confession/holding_hands.png", "伏见宫 · 牵手"],
	["fushimi_final_promise/railing.png", "伏见宫 · 天台"],
	["fushimi_final_promise/stairs.png", "伏见宫 · 两罐牛奶"],
	["fushimi_final_promise/milk.png", "伏见宫 · 温热"],
	["fushimi_final_promise/talking.png", "伏见宫 · 夜谈"],
	["fushimi_final_promise/worried.png", "伏见宫 · 忧心"],
	["fushimi_final_promise/stern.png", "伏见宫 · 逞强"],
	["fushimi_final_promise/holding_hands.png", "伏见宫 · 同行"],
	["middle_school_intro/class_roster.png", "初中 · 分班表"],
	["shirakawa_first_story/challenge.png", "白川 · 挑战"],
	["shirakawa_first_story/pout.png", "白川 · 耍赖"],
	["shirakawa_first_story/hallway_thanks.png", "白川 · 谢谢"],
	["shirakawa_first_story/hallway_pout.png", "白川 · 不服气"],
	["shirakawa_first_story/running.png", "白川 · 追逐"],
	["shirakawa_first_story/hallway.png", "白川 · 长廊"],
	["shirakawa_osmanthus/trail.png", "白川 · 秋游"],
	["shirakawa_osmanthus/tree.png", "白川 · 桂花树"],
	["shirakawa_osmanthus/rain.png", "白川 · 雨落桂花"],
	["shirakawa_osmanthus/petal.png", "白川 · 花瓣"],
	["shirakawa_osmanthus/promise.png", "白川 · 秋日誓言"],
	["shirakawa_puppy/alley.png", "白川 · 小巷"],
	["shirakawa_puppy/puppy.png", "白川 · 小毛球"],
	["shirakawa_puppy/gentle.png", "白川 · 温柔"],
	["shirakawa_puppy/promise.png", "白川 · 共同收养"],
	["shirakawa_puppy/hug.png", "白川 · 拥抱"],
	["shirakawa_confession/window.png", "白川 · 窗边"],
	["shirakawa_confession/hesitant.png", "白川 · 犹豫"],
	["shirakawa_confession/moved.png", "白川 · 心意"],
	["shirakawa_confession/smile.png", "白川 · 答应"],
	["shirakawa_snow/classroom.png", "白川 · 初雪"],
	["shirakawa_snow/scarf.png", "白川 · 围巾"],
	["shirakawa_snow/smile.png", "白川 · 暖意"],
	["shirakawa_snow/snowflakes.png", "白川 · 雪花"],
	["final_exam/Gaokao_POV_01_final_bell.png", "高考之后 · 铃响"],
	["final_exam/Gaokao_POV_02_classroom.png", "高考之后 · 教室"],
	["final_exam/Gaokao_POV_03_corridor.png", "高考之后 · 长廊"],
	["final_exam/Gaokao_POV_04_gate.png", "高考之后 · 校门"],
	["final_exam/Gaokao_POV_05_canopy.png", "高考之后 · 夏天"],
]

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
var image_titles: Dictionary[String, String] = {}
var card_visuals: Array[Control] = []
var card_tweens: Array[Tween] = []
var selected_index := 0
var preview_index := 0
var scroll_hint: Panel


func _ready() -> void:
	load_character_images()
	load_story_cg_images()
	update_count_label()
	build_sleeves()
	build_cards()
	layout_cards(false)
	if Engine.is_editor_hint():
		return
	show_scroll_hint()
	var music_stream := gallery_music.stream.duplicate() as AudioStreamMP3
	music_stream.loop = true
	gallery_music.stream = music_stream
	gallery_music.play()
	back_button.pressed.connect(close_gallery)
	close_button.pressed.connect(func() -> void: preview.hide())
	previous_button.pressed.connect(func() -> void: change_preview(-1))
	previous_button.add_to_group("soft_selection")
	next_button.pressed.connect(func() -> void: change_preview(1))
	next_button.add_to_group("soft_selection")
	animate_cards()


func show_scroll_hint() -> void:
	scroll_hint = Panel.new()
	scroll_hint.name = "ScrollHint"
	scroll_hint.z_index = 30
	scroll_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll_hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	scroll_hint.offset_left = -342.0
	scroll_hint.offset_top = 170.0
	scroll_hint.offset_right = -28.0
	scroll_hint.offset_bottom = 232.0
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff2e2")
	paper.border_color = Color("e4b5ad")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(18)
	paper.shadow_color = Color(0.12, 0.08, 0.20, 0.4)
	paper.shadow_size = 10
	paper.shadow_offset = Vector2(4, 5)
	scroll_hint.add_theme_stylebox_override("panel", paper)
	add_child(scroll_hint)
	var label := Label.new()
	label.text = "试试拨动鼠标滚轮"
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("684574"))
	label.add_theme_font_size_override("font_size", 22)
	scroll_hint.add_child(label)


func load_character_images() -> void:
	var files := DirAccess.get_files_at(CHARACTER_DIRECTORY)
	files.sort()
	for file in files:
		if file.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"]:
			image_paths.append(CHARACTER_DIRECTORY.path_join(file))


func load_story_cg_images() -> void:
	for entry in STORY_CG:
		var path: String = "res://images/" + str(entry[0])
		if not ResourceLoader.exists(path):
			push_warning("Gallery CG missing: %s" % path)
			continue
		image_paths.append(path)
		image_titles[path] = str(entry[1])


func image_title(index: int) -> String:
	var path := image_paths[index]
	return image_titles.get(path, path.get_file().get_basename().replace("_", " "))


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
	visual.add_to_group("soft_selection")
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
	caption.text = image_title(index)
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
		tween.tween_property(card, "position:y", final_y, 1.35).set_delay(minf(index * 0.16, 0.8)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
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
	var name := image_title(selected_index)
	count_label.text = "%d / %d  ·  %s  ·  滚轮切换，点击照片查看" % [selected_index + 1, image_paths.size(), name]


func on_card_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		show_preview(index)


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or image_paths.is_empty() or not (event is InputEventMouseButton) or not event.pressed:
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		if is_instance_valid(scroll_hint):
			scroll_hint.hide()
		if preview.visible:
			change_preview(-1)
		else:
			select_photo(-1)
		get_viewport().set_input_as_handled()
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		if is_instance_valid(scroll_hint):
			scroll_hint.hide()
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


func close_gallery(with_sound: bool = true) -> void:
	SceneFade.play_action(queue_free, 1.0, with_sound)


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
				close_gallery(false)
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
