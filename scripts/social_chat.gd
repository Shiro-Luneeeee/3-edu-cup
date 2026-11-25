extends ColorRect

const SocialCharacters := preload("res://scripts/social_characters.gd")
const AiRolePrompts := preload("res://scripts/ai_role_prompts.gd")
const INK := Color(0.35, 0.23, 0.42)
const SOFT_INK := Color(0.53, 0.39, 0.55)

var character := SocialCharacters.YUE
var busy := false
var messages: VBoxContainer
var scroller: ScrollContainer
var input: LineEdit
var send_button: Button
var status_label: Label


func _ready() -> void:
	_build_ui()
	_render_history()
	_update_availability()
	LocalDialogue.availability_changed.connect(_update_availability)


func _build_ui() -> void:
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.anchor_left = 0.12
	frame.anchor_top = 0.07
	frame.anchor_right = 0.88
	frame.anchor_bottom = 0.93
	frame.offset_left = 0
	frame.offset_top = 0
	frame.offset_right = 0
	frame.offset_bottom = 0
	frame.add_theme_stylebox_override("panel", _paper_style(Color("fff8f2"), 24, 0))
	add_child(frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	frame.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	column.add_child(header)
	var avatar := TextureRect.new()
	avatar.texture = SocialCharacters.avatar(character)
	avatar.custom_minimum_size = Vector2(72, 72)
	avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(avatar)
	var heading := VBoxContainer.new()
	header.add_child(heading)
	var name_label := Label.new()
	name_label.text = "与%s的手记" % character
	name_label.add_theme_color_override("font_color", INK)
	name_label.add_theme_font_size_override("font_size", 31)
	heading.add_child(name_label)
	var hint := Label.new()
	hint.text = "在这里，说些剧本之外的话。"
	hint.add_theme_color_override("font_color", SOFT_INK)
	hint.add_theme_font_size_override("font_size", 17)
	heading.add_child(hint)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "返回社交  ×"
	_style_button(close_button, false)
	close_button.pressed.connect(queue_free)
	header.add_child(close_button)
	var line := HSeparator.new()
	column.add_child(line)
	scroller = ScrollContainer.new()
	scroller.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroller.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroller)
	messages = VBoxContainer.new()
	messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messages.add_theme_constant_override("separation", 12)
	scroller.add_child(messages)
	status_label = Label.new()
	status_label.add_theme_color_override("font_color", SOFT_INK)
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(status_label)
	var composer := HBoxContainer.new()
	composer.add_theme_constant_override("separation", 12)
	column.add_child(composer)
	input = LineEdit.new()
	input.placeholder_text = "写一句想对她说的话……"
	input.max_length = 200
	input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	input.custom_minimum_size = Vector2(0, 52)
	input.add_theme_font_size_override("font_size", 20)
	input.text_submitted.connect(func(_text: String) -> void: send_message())
	composer.add_child(input)
	send_button = Button.new()
	send_button.text = "寄出  ›"
	_style_button(send_button, true)
	send_button.pressed.connect(send_message)
	composer.add_child(send_button)


func _paper_style(color: Color, radius: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(margin if margin > 0 else 28)
	style.border_color = Color("c9adc4")
	style.set_border_width_all(2)
	return style


func _style_button(button: Button, primary: bool) -> void:
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color.WHITE if primary else INK)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else INK)
	button.add_theme_stylebox_override("normal", _paper_style(Color("795181") if primary else Color("f2e2ed"), 18, 12))
	button.add_theme_stylebox_override("hover", _paper_style(Color("936397") if primary else Color("ead4e6"), 18, 12))
	button.add_theme_stylebox_override("pressed", _paper_style(Color("64436e") if primary else Color("e3c9de"), 18, 12))


func _render_history() -> void:
	var history: Array = PlayerState.social_chat_history.get(character, [])
	if history.is_empty():
		_add_line(character, "嗨，%s。今天想和我聊些什么？" % PlayerState.player_name, false)
	for entry in history:
		_add_line(PlayerState.player_name if entry["role"] == "user" else character, entry["content"], entry["role"] == "user")


func _add_line(speaker: String, content: String, from_player: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if from_player else BoxContainer.ALIGNMENT_BEGIN
	messages.add_child(row)
	var bubble := PanelContainer.new()
	bubble.custom_minimum_size = Vector2(600, 0)
	bubble.add_theme_stylebox_override("panel", _paper_style(Color("f1dfe9") if from_player else Color("fffdf9"), 15, 12))
	row.add_child(bubble)
	var label := Label.new()
	label.text = "%s\n%s" % [speaker, content]
	label.add_theme_color_override("font_color", INK)
	label.add_theme_font_size_override("font_size", 19)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 548
	bubble.add_child(label)
	call_deferred("_scroll_to_bottom")


func _scroll_to_bottom() -> void:
	if is_instance_valid(scroller):
		scroller.scroll_vertical = int(scroller.get_v_scroll_bar().max_value)


func _update_availability() -> void:
	input.editable = LocalDialogue.available and not busy
	send_button.disabled = not LocalDialogue.available or busy
	if busy:
		status_label.text = "%s正在读你的话……" % character
	elif LocalDialogue.checking:
		status_label.text = "正在检查本地模型……"
	elif not LocalDialogue.available:
		status_label.text = "本地对话暂不可用：%s" % LocalDialogue.reason
	else:
		status_label.text = "本地生成 · 本回合对话好感度 +%d/%d · 对话只保存在这份游戏存档中" % [PlayerState.free_chat_affection_this_round.get(character, 0), PlayerState.FREE_CHAT_AFFECTION_ROUND_CAP]


func send_message() -> void:
	var outgoing := input.text.strip_edges()
	if busy or not LocalDialogue.available or outgoing.is_empty():
		return
	busy = true
	input.clear()
	_add_line(PlayerState.player_name, outgoing, true)
	_update_availability()
	var history: Array = PlayerState.social_chat_history.get(character, []).duplicate(true)
	var context: Array = [{"role": "system", "content": _role_prompt()}]
	for entry in history.slice(-12):
		context.append(entry)
	context.append({"role": "user", "content": outgoing})
	var answer: Dictionary = await LocalDialogue.reply(context)
	if not is_inside_tree():
		return
	busy = false
	if answer.get("ok", false):
		var response := str(answer["text"]).left(500)
		_add_line(character, response, false)
		history.append({"role": "user", "content": outgoing})
		history.append({"role": "assistant", "content": response})
		PlayerState.social_chat_history[character] = history.slice(-20)
		PlayerState.record_free_chat_affection(character)
	else:
		_add_line("手记", "这次没有收到回复。%s" % str(answer.get("error", "")), false)
	_update_availability()


func _role_prompt() -> String:
	return AiRolePrompts.build(character)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		queue_free()
