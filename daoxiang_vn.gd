extends "res://story_dialogue.gd"

const PARK_BACKGROUND: Texture2D = preload("res://images/vn/daoxiang/daoxiang_park_background.png")
const RIVER_BACKGROUND: Texture2D = preload("res://images/vn/daoxiang/daoxiang_river_background.png")
const LITTLE_CHILD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_little_child_cutout.png")
const CHILD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_child_cutout.png")
const SAD: Texture2D = preload("res://images/vn/daoxiang/daoxiang_sad_cutout.png")
const CONFESSION: Texture2D = preload("res://images/vn/daoxiang/daoxiang_confession_cutout.png")

var act := 1
var story_lines: Array[Dictionary] = []
var choice_bar := HBoxContainer.new()
var choice_resolved := false


func _ready() -> void:
	build_lines()
	yue_portrait.texture = (LITTLE_CHILD if PlayerState.get_age_years() <= 9 else CHILD) if act == 1 else (SAD if act == 2 else CONFESSION)
	create_choices()
	super._ready()
	place_portrait()


func lines() -> Array:
	return story_lines


func final_button_text() -> String:
	return "回到公园  ›"


func build_lines() -> void:
	match act:
		1:
			story_lines = [
				{"text": "公园的树下，坐着一个蓝发女孩。她正把短句写在两张小纸条上。", "background": PARK_BACKGROUND, "show_portrait": false},
				{"speaker": "daoxiang", "text": "风没有写信，树叶替它落了款。我叫稻香粽子。你也写一句吗？我们交换。", "show_portrait": true},
				{"text": "她把一张折好的纸递给你。"},
				{"speaker": "note", "text": "如果有一天我不相信春天了，请把这张纸还给我。", "choice": true},
				{"speaker": "daoxiang", "text": "原来你写的是——「%s」。好，那我们就是互相保管秘密的人了。"},
				{"text": "她将你的纸条小心收进书里。风吹过树梢，你也收好了她的那一张。"},
			]
		2:
			story_lines = [
				{"text": "中考放榜后的傍晚，她独自坐在河边，手里攥着那张旧纸条。", "background": RIVER_BACKGROUND, "show_portrait": true},
				{"speaker": "daoxiang", "text": "我没有考上想去的学校。以前读泰戈尔，我总记得一句很好听的话：世界以痛吻我，我却报之以歌。"},
				{"speaker": "daoxiang", "text": "后来我才认真看《飞鸟集》第167首的原文。"},
				{"text": "The world has kissed my soul with its pain, asking for its return in songs."},
				{"speaker": "daoxiang", "text": "世界以痛亲吻我的灵魂，还向我索要歌声。原来它伤了你，竟还要你唱给它听。"},
				{"speaker": "daoxiang", "text": "那么爱生命、爱世界的泰戈尔，也会有唱不出来的时候吗？"},
				{"speaker": "daoxiang", "text": "我原以为自己不会变成一个只在乎分数的人。也许这是我最后一次不甘心。"},
				{"speaker": "player", "text": "那今天就不要唱。把沉默交给河，把明天交给明天。我坐在这里，等你愿意说话。"},
				{"text": "她没有立刻笑，只是慢慢松开了攥着纸条的手。河水替你们保管了这一阵沉默。"},
			]
		3:
			var reply := PlayerState.daoxiang_reply if not PlayerState.daoxiang_reply.is_empty() else "春天若迟到，我陪你等"
			story_lines = [
				{"text": "又一年夏天。你们在公园的树下重逢，她把那张旧纸条还给你。", "background": PARK_BACKGROUND, "show_portrait": true},
				{"speaker": "note", "text": "春天没有替我赢回来什么。可我走过最难过的那段路时，你一直在。"},
				{"speaker": "daoxiang", "text": "那天你说：「%s」。后来我才懂，有人愿意听我说完，就是春天的一部分。" % reply},
				{"speaker": "daoxiang", "text": "我还是想相信世界有爱。现在，我能说出一个确切的理由了。"},
				{"speaker": "daoxiang", "text": "以后散步，可以也叫上我吗？不管去哪里。"},
				{"speaker": "player", "text": "好。以后每一个有风的日子，我们一起走。"},
			]


func create_choices() -> void:
	choice_bar.add_theme_constant_override("separation", 14)
	choice_bar.visible = false
	var content: VBoxContainer = dialogue_box.get_node("Content")
	content.add_child(choice_bar)
	content.move_child(choice_bar, next_button.get_index())
	for option in ["春天若迟到，我陪你等。", "我会记得，再把它还给你。"]:
		var button := Button.new()
		button.text = option
		button.custom_minimum_size = Vector2(0, 34)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_color", Color("fff5ed"))
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, next_button.get_theme_stylebox(state))
		button.pressed.connect(choose_reply.bind(choice_bar.get_child_count()))
		choice_bar.add_child(button)


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_yue_background(line["background"], line.get("show_portrait", false))
	elif line.get("show_portrait", false):
		yue_portrait.show()
	var who: String = line.get("speaker", "")
	yue_portrait.modulate = Color.WHITE if who == "daoxiang" else LISTENING_TINT
	match who:
		"daoxiang": return "稻香粽子"
		"player": return PlayerState.player_name if not PlayerState.player_name.is_empty() else "你"
		"note": return "纸条"
	return ""


func advance() -> void:
	if line_index >= 0 and line_index < story_lines.size() and story_lines[line_index].get("choice", false) and not choice_resolved:
		return
	super.advance()
	if line_index >= story_lines.size():
		return
	var waiting_for_choice: bool = story_lines[line_index].get("choice", false) and not choice_resolved
	choice_bar.visible = waiting_for_choice
	next_button.visible = not waiting_for_choice


func choose_reply(index: int) -> void:
	if line_index < 0 or not story_lines[line_index].get("choice", false) or choice_resolved:
		return
	PlayerState.daoxiang_reply = "春天若迟到，我陪你等" if index == 0 else "我会记得，再把它还给你"
	PlayerState.changed.emit()
	story_lines[4]["text"] = "原来你写的是——「%s」。好，那我们就是互相保管秘密的人了。" % PlayerState.daoxiang_reply
	choice_resolved = true
	advance()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		queue_free()
		return
	super._unhandled_key_input(event)
