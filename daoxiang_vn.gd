extends Control

signal finished

const PARK_BACKGROUND: Texture2D = preload("res://images/vn/daoxiang/daoxiang_park_background.png")
const RIVER_BACKGROUND: Texture2D = preload("res://images/vn/daoxiang/daoxiang_river_background.png")
const CHILD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_child_cutout.png")
const LITTLE_CHILD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_little_child_cutout.png")
const SAD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_sad_cutout.png")
const CONFESSION: Texture2D = preload("res://images/vn/daoxiang/daoxiang_confession_cutout.png")
const PAPER: Texture2D = preload("res://images/aged_blank_a4_paper.png")
const TITLES := ["", "风替我们落款", "河流没有回答", "世界没有童话，我们还有彼此"]

var act := 1
var beats: Array[Dictionary] = []
var beat_index := 0
var reveal := 0.0
var closing := false

var background := TextureRect.new()
var portrait := TextureRect.new()
var paper := TextureRect.new()
var heading := Label.new()
var speaker := Label.new()
var body := RichTextLabel.new()
var counter := Label.new()
var next_button := Button.new()
var close_button := Button.new()
var choice_buttons: Array[Button] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	build_story()
	background.texture = RIVER_BACKGROUND if act == 2 else PARK_BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.texture = (LITTLE_CHILD if PlayerState.get_age_years() <= 9 else CHILD) if act == 1 else (SAD if act == 2 else CONFESSION)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	var paper_fill := AtlasTexture.new()
	paper_fill.atlas = PAPER
	paper_fill.region = Rect2(PAPER.get_size() * Vector2(0.07, 0.06), PAPER.get_size() * Vector2(0.86, 0.87))
	paper.texture = paper_fill
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode = TextureRect.STRETCH_SCALE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	for item in [heading, speaker, body, counter, next_button, close_button]:
		paper.add_child(item)
		item.add_theme_color_override("font_color", Color("514d54"))
	heading.text = "稻香粽子 · 第%d幕" % act
	heading.add_theme_font_size_override("font_size", 24)
	speaker.add_theme_font_size_override("font_size", 18)
	speaker.add_theme_color_override("font_color", Color("93704e"))
	body.add_theme_color_override("default_color", Color("514d54"))
	body.scroll_active = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter.add_theme_color_override("font_color", Color("8a8075"))
	counter.add_theme_font_size_override("font_size", 14)
	for button in [next_button, close_button]:
		style_button(button)
	next_button.pressed.connect(advance)
	close_button.text = "返回公园"
	close_button.pressed.connect(close_story)
	for index in 2:
		var choice := Button.new()
		style_button(choice)
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.visible = false
		paper.add_child(choice)
		choice.pressed.connect(choose_reply.bind(index))
		choice_buttons.append(choice)
	resized.connect(layout_page)
	layout_page()
	show_beat()


func build_story() -> void:
	match act:
		1:
			beats = [
				{"speaker": "", "text": "公园的树下，坐着一个蓝发女孩。她正把短句写在两张小纸条上。"},
				{"speaker": "稻香粽子", "text": "风没有写信，树叶替它落了款。\n\n我叫稻香粽子。你也写一句吗？我们交换。"},
				{"speaker": "", "text": "她把一张折好的纸递给你。"},
				{"speaker": "纸条", "text": "如果有一天我不相信春天了，请把这张纸还给我。", "choice": true},
				{"speaker": "稻香粽子", "text": "原来你写的是——\n\n「%s」\n\n好。那我们就是互相保管秘密的人了。"},
				{"speaker": "", "text": "她将你的纸条小心收进书里。风吹过树梢，你也收好了她的那一张。"},
			]
		2:
			beats = [
				{"speaker": "", "text": "中考放榜后的傍晚，她独自坐在河边，手里攥着那张旧纸条。"},
				{"speaker": "稻香粽子", "text": "我没有考上想去的学校。\n\n以前读泰戈尔，我总记得一句很好听的话：世界以痛吻我，我却报之以歌。"},
				{"speaker": "稻香粽子", "text": "后来我才认真看原文。\n\nThe world has kissed my soul with its pain, asking for its return in songs.\n\n——《飞鸟集》第167首"},
				{"speaker": "稻香粽子", "text": "世界以痛亲吻我的灵魂，还向我索要歌声。\n\n原来它伤了你，竟还要你唱给它听。"},
				{"speaker": "稻香粽子", "text": "那么爱生命、爱世界的泰戈尔，也会有唱不出来的时候吗？\n\n我原以为自己不会变成一个只在乎分数的人。也许这是我最后一次不甘心。"},
				{"speaker": "你", "text": "那今天就不要唱。\n\n把沉默交给河，把明天交给明天。我坐在这里，等你愿意说话。"},
				{"speaker": "", "text": "她没有立刻笑，只是慢慢松开了攥着纸条的手。河水替你们保管了这一阵沉默。"},
			]
		3:
			beats = [
				{"speaker": "", "text": "又一年夏天。你们在公园的树下重逢，她把那张旧纸条还给你。"},
				{"speaker": "纸条背面", "text": "春天没有替我赢回来什么。\n\n可我走过最难过的那段路时，你一直在。"},
				{"speaker": "稻香粽子", "text": "那天你说：「%s」\n\n后来我才懂，有人愿意听我说完，就是春天的一部分。"},
				{"speaker": "稻香粽子", "text": "我还是想相信世界有爱。现在，我能说出一个确切的理由了。"},
				{"speaker": "稻香粽子", "text": "以后散步，可以也叫上我吗？\n\n不管去哪里。"},
				{"speaker": "你", "text": "好。以后每一个有风的日子，我们一起走。"},
		]
	if act == 1:
		beats[4]["text"] = String(beats[4]["text"]) % PlayerState.daoxiang_reply
	if act == 3:
		var reply := PlayerState.daoxiang_reply if not PlayerState.daoxiang_reply.is_empty() else "春天若迟到，我陪你等"
		beats[2]["text"] = String(beats[2]["text"]) % reply


func style_button(button: Button) -> void:
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("font_hover_color", Color("93704e"))
	button.add_theme_color_override("font_pressed_color", Color("514d54"))
	button.add_theme_color_override("font_focus_color", Color("514d54"))
	button.add_theme_font_size_override("font_size", 17)


func layout_page() -> void:
	var factor := minf(size.x / 1152.0, size.y / 648.0)
	portrait.position = Vector2(size.x * 0.025, size.y * 0.035)
	portrait.size = Vector2(size.x * 0.66, size.y * 0.96)
	paper.size = Vector2(size.x * 0.34 / factor, size.y / factor)
	paper.scale = Vector2.ONE * factor
	paper.position = Vector2(size.x * 0.66, 0.0)
	var inner_width := paper.size.x - 64.0
	heading.position = Vector2(32, 40)
	heading.size = Vector2(inner_width, 36)
	speaker.position = Vector2(32, 112)
	speaker.size = Vector2(inner_width, 30)
	body.position = Vector2(32, 158)
	body.size = Vector2(inner_width, paper.size.y - 300)
	body.add_theme_font_size_override("normal_font_size", 17)
	body.add_theme_constant_override("normal_line_separation", 7)
	counter.position = Vector2(32, paper.size.y - 122)
	counter.size = Vector2(inner_width, 24)
	close_button.position = Vector2(24, paper.size.y - 67)
	close_button.size = Vector2(124, 38)
	next_button.position = Vector2(paper.size.x - 164, paper.size.y - 67)
	next_button.size = Vector2(140, 38)
	for index in choice_buttons.size():
		choice_buttons[index].position = Vector2(28, paper.size.y - 207 + index * 40)
		choice_buttons[index].size = Vector2(inner_width + 8, 38)


func show_beat() -> void:
	var beat: Dictionary = beats[beat_index]
	speaker.text = String(beat["speaker"])
	body.text = String(beat["text"])
	body.visible_characters = 0
	reveal = 0.0
	counter.text = "%s  ·  %d / %d" % [TITLES[act], beat_index + 1, beats.size()]
	var is_choice: bool = beat.get("choice", false)
	next_button.visible = not is_choice
	next_button.text = "收好这页  →" if beat_index == beats.size() - 1 else "继续阅读  →"
	for choice in choice_buttons:
		choice.visible = false
	if is_choice:
		choice_buttons[0].text = "春天若迟到，我陪你等。"
		choice_buttons[1].text = "我会记得，再把它还给你。"


func _process(delta: float) -> void:
	if body.visible_characters >= body.get_total_character_count():
		return
	reveal += delta * 42.0
	body.visible_characters = mini(int(reveal), body.get_total_character_count())
	if body.visible_characters >= body.get_total_character_count() and beats[beat_index].get("choice", false):
		for choice in choice_buttons:
			choice.visible = true


func advance() -> void:
	if closing:
		return
	if body.visible_characters < body.get_total_character_count():
		body.visible_characters = body.get_total_character_count()
		reveal = float(body.visible_characters)
		return
	if beat_index < beats.size() - 1:
		beat_index += 1
		show_beat()
	else:
		PlayerState.complete_daoxiang_act(act)
		finished.emit()
		close_story()


func choose_reply(index: int) -> void:
	if body.visible_characters < body.get_total_character_count():
		return
	PlayerState.daoxiang_reply = "春天若迟到，我陪你等" if index == 0 else "我会记得，再把它还给你"
	PlayerState.changed.emit()
	beats[4]["text"] = "原来你写的是——\n\n「%s」\n\n好。那我们就是互相保管秘密的人了。" % PlayerState.daoxiang_reply
	beat_index += 1
	show_beat()


func close_story() -> void:
	if closing:
		return
	closing = true
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_story()
