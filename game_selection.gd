extends Control

const GameEntry = preload("res://game_entry.gd")
const GameAesthetic := preload("res://game_aesthetic.gd")
const BEDROOM_SCENE := "res://bedroom.tscn"
const STAGE_SIZE := Vector2(1152, 648)
const GAMES = [
	preload("res://data/games/univerthm.tres"),
	preload("res://data/games/phantom_sonnet.tres"),
	preload("res://data/games/pale_myth_heart_sky.tres"),
]
const FRONT_POSITION := Vector2(248, 164)
const CARD_SIZE := Vector2(408, 363)
const ANIMATION_TIME := 0.48

@onready var stage: Control = $Stage

var selected_index := 0
var transitioning := false
var launching := false
var cards: Array[Node2D] = []
var paper: Panel
var title_label: Label
var description_label: RichTextLabel
var cost_label: Label
var effect_label: Label
var page_label: Label
var balance_label: Label
var aesthetic_bar: ProgressBar
var aesthetic_amount_label: Label
var aesthetic_reward_label: Label
var aesthetic_detail_label: Label
var action_button: Button
var story_overlay: ColorRect
var aesthetic_reward_overlay: ColorRect
var pending_entry: GameEntry


func _ready() -> void:
	stage.size = STAGE_SIZE
	build_interface()
	resized.connect(update_layout)
	update_layout()
	apply_selection()


func build_interface() -> void:
	var heading := make_label("游戏选择", Vector2(42, 30), Vector2(420, 76), 53, Color("fff1e0"))
	stage.add_child(heading)
	var subtitle := make_label("课余时光  /  小游戏收藏夹", Vector2(47, 96), Vector2(450, 28), 17, Color("f5d7d8"))
	stage.add_child(subtitle)
	var aesthetic_heading := make_label("游戏审美积累", Vector2(47, 129), Vector2(150, 28), 18, Color("fff0dc"))
	stage.add_child(aesthetic_heading)
	aesthetic_bar = ProgressBar.new()
	aesthetic_bar.position = Vector2(198, 134)
	aesthetic_bar.size = Vector2(380, 16)
	aesthetic_bar.show_percentage = false
	aesthetic_bar.max_value = GameAesthetic.target_points()
	aesthetic_bar.tooltip_text = "每款游戏前 3 次完成时按价格积累审美，之后收益逐渐减少。积满后体力上限翻倍。"
	var meter_background := make_style(Color("f8e9dd"), Color("d5a8ad"), 8, 1)
	meter_background.shadow_size = 0
	aesthetic_bar.add_theme_stylebox_override("background", meter_background)
	var meter_fill := make_style(Color("b474af"), Color("f6d4ad"), 8, 1)
	meter_fill.shadow_size = 0
	aesthetic_bar.add_theme_stylebox_override("fill", meter_fill)
	stage.add_child(aesthetic_bar)
	aesthetic_amount_label = make_label("", Vector2(586, 124), Vector2(142, 31), 18, Color("fff0dc"))
	aesthetic_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(aesthetic_amount_label)
	aesthetic_reward_label = make_label("", Vector2(753, 127), Vector2(359, 27), 17, Color("fff0dc"))
	aesthetic_reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(aesthetic_reward_label)
	balance_label = make_label("", Vector2(742, 94), Vector2(370, 30), 21, Color("fff0dc"))
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stage.add_child(balance_label)
	PlayerState.changed.connect(update_information)

	var back := make_button("⌂  返回卧室", Vector2(957, 36), Vector2(158, 42))
	back.pressed.connect(SceneFade.change_to.bind(BEDROOM_SCENE, -1.0))
	stage.add_child(back)

	# Add the rear covers first so the selected cover can sit in front.
	for index in range(GAMES.size() - 1, -1, -1):
		var card := make_cover(index)
		stage.add_child(card)
		cards.insert(0, card)

	paper = Panel.new()
	paper.position = Vector2(731, 151)
	paper.size = Vector2(385, 423)
	paper.add_theme_stylebox_override("panel", make_style(Color("fff0e2"), Color("e9baaa"), 20, 2))
	stage.add_child(paper)

	title_label = make_label("", Vector2(30, 28), Vector2(325, 81), 42, Color("604374"))
	paper.add_child(title_label)
	description_label = RichTextLabel.new()
	description_label.position = Vector2(31, 126)
	description_label.size = Vector2(322, 115)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.add_theme_font_size_override("normal_font_size", 19)
	description_label.add_theme_color_override("default_color", Color("765d77"))
	paper.add_child(description_label)
	cost_label = make_label("", Vector2(31, 243), Vector2(322, 32), 19, Color("715584"))
	paper.add_child(cost_label)
	effect_label = make_label("", Vector2(31, 275), Vector2(322, 32), 19, Color("715584"))
	paper.add_child(effect_label)
	aesthetic_detail_label = make_label("", Vector2(31, 307), Vector2(322, 29), 17, Color("875885"))
	paper.add_child(aesthetic_detail_label)
	action_button = make_button("", Vector2(35, 344), Vector2(315, 56))
	action_button.pressed.connect(activate_selected_game)
	paper.add_child(action_button)

	var previous := make_button("‹", Vector2(279, 559), Vector2(50, 49))
	previous.pressed.connect(change_game.bind(-1))
	stage.add_child(previous)
	page_label = make_label("", Vector2(340, 565), Vector2(238, 34), 22, Color("fff0dc"))
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage.add_child(page_label)
	var next := make_button("›", Vector2(588, 559), Vector2(50, 49))
	next.pressed.connect(change_game.bind(1))
	stage.add_child(next)


func make_cover(index: int) -> Node2D:
	var wrapper := Node2D.new()
	wrapper.name = "GameCover%d" % index
	var card := Button.new()
	card.name = "CoverButton"
	card.clip_contents = true
	card.size = CARD_SIZE
	card.flat = true
	card.focus_mode = Control.FOCUS_NONE
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.add_theme_stylebox_override("normal", make_style(Color("eee1ee"), Color("f8d6ac"), 18, 3))
	card.add_theme_stylebox_override("hover", make_style(Color("fff0e2"), Color("ffda98"), 18, 4))
	card.add_theme_stylebox_override("pressed", make_style(Color("fff0e2"), Color("ffda98"), 18, 4))
	card.pressed.connect(on_cover_pressed.bind(index))
	wrapper.add_child(card)
	var art := TextureRect.new()
	art.texture = GAMES[index].cover
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(art)
	var spine := ColorRect.new()
	spine.color = Color(0.23, 0.15, 0.34, 0.65)
	spine.position = Vector2.ZERO
	spine.size = Vector2(13, CARD_SIZE.y)
	spine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(spine)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	shade.offset_top = -91
	shade.color = Color(0.24, 0.16, 0.38, 0.76)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(shade)
	var label := make_label(GAMES[index].title, Vector2(21, 17), Vector2(330, 58), 30, Color("fff5e8"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(label)
	return wrapper


func card_position(depth: int) -> Vector2:
	return FRONT_POSITION + Vector2(-84 * depth, 72 * depth)


func card_scale(depth: int) -> Vector2:
	return Vector2.ONE * (1.0 - depth * 0.14)


func card_tint(depth: int) -> Color:
	return Color.WHITE if depth == 0 else Color(0.91 - depth * 0.08, 0.87 - depth * 0.08, 0.95, 0.86 - depth * 0.10)


func apply_selection() -> void:
	for card_index in cards.size():
		var depth := posmod(card_index - selected_index, cards.size())
		var card := cards[card_index]
		card.position = card_position(depth)
		card.scale = card_scale(depth)
		card.rotation = -0.025 * depth
		card.skew = -0.055 * depth
		card.modulate = card_tint(depth)
		card.z_index = 10 - depth
	update_information()


func update_information() -> void:
	var entry: GameEntry = GAMES[selected_index]
	title_label.text = entry.title
	title_label.add_theme_font_size_override("font_size", 28 if entry.title.length() > 12 else (36 if entry.title.length() > 7 else 42))
	description_label.text = entry.description
	description_label.scroll_to_line(0)
	cost_label.text = "体力消耗：%d" % entry.energy_cost
	effect_label.text = "完成效果：%s" % entry.effect_description
	balance_label.text = "余额：%d 金" % PlayerState.money
	aesthetic_bar.value = PlayerState.game_aesthetic_points
	aesthetic_amount_label.text = "%d / %d" % [PlayerState.game_aesthetic_points, GameAesthetic.target_points()]
	aesthetic_reward_label.text = "已获得 · 体力上限 ×2" if PlayerState.game_aesthetic_reward_claimed else "积满奖励 · 体力上限 ×2"
	var completed_plays: int = PlayerState.game_play_counts.get(entry.id, 0)
	aesthetic_detail_label.text = "审美已满 · 继续游玩无额外积累" if PlayerState.game_aesthetic_reward_claimed else "第 %d 次完成 · 审美 +%d" % [completed_plays + 1, PlayerState.game_aesthetic_gain(entry.id, entry.price)]
	var owned := PlayerState.owns_game(entry.id)
	if owned:
		action_button.disabled = PlayerState.current_energy < entry.energy_cost
		action_button.text = "体力不足" if action_button.disabled else "开始游戏"
	else:
		action_button.disabled = PlayerState.money < entry.price
		if action_button.disabled:
			action_button.text = "金钱不足 · %d 金" % entry.price
		elif PlayerState.current_energy < entry.energy_cost:
			action_button.text = "购买游戏 · %d 金" % entry.price
		else:
			action_button.text = "购买并游玩 · %d 金" % entry.price
	page_label.text = "●".repeat(selected_index + 1) + "○".repeat(GAMES.size() - selected_index - 1)


func change_game(direction: int) -> void:
	if transitioning or launching:
		return
	transitioning = true
	var old_index := selected_index
	var outgoing := cards[selected_index]
	var next_index := posmod(selected_index + direction, cards.size())
	var incoming := cards[next_index]
	outgoing.z_index = 20
	incoming.z_index = 19
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(outgoing, "position", Vector2(295, 704), ANIMATION_TIME)
	tween.tween_property(outgoing, "scale", Vector2(1.08, 1.08), ANIMATION_TIME)
	tween.tween_property(outgoing, "rotation", 0.09 if direction > 0 else -0.09, ANIMATION_TIME)
	tween.tween_property(outgoing, "skew", 0.04, ANIMATION_TIME)
	tween.tween_property(outgoing, "modulate:a", 0.0, ANIMATION_TIME)
	tween.tween_property(incoming, "position", FRONT_POSITION, ANIMATION_TIME)
	tween.tween_property(incoming, "scale", Vector2.ONE, ANIMATION_TIME)
	tween.tween_property(incoming, "rotation", 0.0, ANIMATION_TIME)
	tween.tween_property(incoming, "skew", 0.0, ANIMATION_TIME)
	tween.tween_property(incoming, "modulate", Color.WHITE, ANIMATION_TIME)
	for card_index in cards.size():
		if card_index == selected_index or card_index == next_index:
			continue
		var depth := posmod(card_index - next_index, cards.size())
		var card := cards[card_index]
		tween.tween_property(card, "position", card_position(depth), ANIMATION_TIME)
		tween.tween_property(card, "scale", card_scale(depth), ANIMATION_TIME)
		tween.tween_property(card, "rotation", -0.025 * depth, ANIMATION_TIME)
		tween.tween_property(card, "skew", -0.055 * depth, ANIMATION_TIME)
		tween.tween_property(card, "modulate", card_tint(depth), ANIMATION_TIME)
	tween.tween_property(paper, "modulate:a", 0.0, ANIMATION_TIME * 0.42)
	await get_tree().create_timer(ANIMATION_TIME * 0.48).timeout
	selected_index = next_index
	update_information()
	var reveal := create_tween()
	reveal.tween_property(paper, "modulate:a", 1.0, ANIMATION_TIME * 0.52)
	await tween.finished
	apply_selection()
	outgoing.modulate.a = 0.0
	var return_tween := create_tween()
	return_tween.tween_property(outgoing, "modulate:a", card_tint(posmod(old_index - selected_index, cards.size())).a, 0.16)
	await return_tween.finished
	transitioning = false


func on_cover_pressed(index: int) -> void:
	if transitioning or launching:
		return
	if index == selected_index:
		activate_selected_game()
	else:
		change_game(1 if posmod(index - selected_index, cards.size()) == 1 else -1)


func activate_selected_game() -> void:
	if transitioning or launching:
		return
	var entry: GameEntry = GAMES[selected_index]
	if not PlayerState.owns_game(entry.id) and not PlayerState.try_buy_game(entry.id, entry.price):
		update_information()
		return
	if not PlayerState.try_start_game(entry.id, entry.energy_cost):
		update_information()
		return
	launching = true
	pending_entry = entry
	show_play_story(entry)


func show_play_story(entry: GameEntry) -> void:
	story_overlay = ColorRect.new()
	story_overlay.name = "PlayStory"
	story_overlay.color = Color(0.09, 0.06, 0.17, 0.82)
	story_overlay.size = STAGE_SIZE
	story_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	story_overlay.z_index = 50
	stage.add_child(story_overlay)

	var panel := Panel.new()
	panel.position = Vector2(216, 113)
	panel.size = Vector2(720, 424)
	panel.add_theme_stylebox_override("panel", make_style(Color("fff0e2"), Color("e9baaa"), 24, 2))
	story_overlay.add_child(panel)

	var heading := make_label(entry.title, Vector2(40, 29), Vector2(640, 64), 32, Color("604374"))
	panel.add_child(heading)
	var story := RichTextLabel.new()
	story.text = entry.play_story
	story.position = Vector2(42, 102)
	story.size = Vector2(636, 180)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("normal_font_size", 23)
	story.add_theme_color_override("default_color", Color("765d77"))
	panel.add_child(story)
	var result := make_label("游玩结束  ·  " + entry.effect_description, Vector2(43, 289), Vector2(630, 35), 21, Color("715584"))
	panel.add_child(result)
	var done := make_button("结束游玩", Vector2(222, 348), Vector2(276, 55))
	done.pressed.connect(finish_play_story)
	panel.add_child(done)


func finish_play_story() -> void:
	if pending_entry == null:
		return
	var previous_points := PlayerState.game_aesthetic_points
	PlayerState.reward_game(pending_entry.reward_stat, pending_entry.reward_amount)
	var aesthetic_result := PlayerState.record_game_play(pending_entry.id, pending_entry.price)
	pending_entry = null
	story_overlay.queue_free()
	story_overlay = null
	launching = false
	update_information()
	if aesthetic_result["gain"] > 0:
		aesthetic_bar.value = previous_points
		create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).tween_property(aesthetic_bar, "value", PlayerState.game_aesthetic_points, 0.7)
	if aesthetic_result["reward_unlocked"]:
		show_aesthetic_reward()


func show_aesthetic_reward() -> void:
	aesthetic_reward_overlay = ColorRect.new()
	aesthetic_reward_overlay.color = Color(0.14, 0.09, 0.21, 0.78)
	aesthetic_reward_overlay.size = STAGE_SIZE
	aesthetic_reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	aesthetic_reward_overlay.z_index = 60
	stage.add_child(aesthetic_reward_overlay)
	var letter := Panel.new()
	letter.position = Vector2(252, 172)
	letter.size = Vector2(648, 310)
	letter.add_theme_stylebox_override("panel", make_style(Color("fff3e3"), Color("e7baa8"), 23, 2))
	aesthetic_reward_overlay.add_child(letter)
	var heading := make_label("✦  游戏审美积累已满  ✦", Vector2(34, 33), Vector2(580, 56), 32, Color("704978"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.add_child(heading)
	var message := make_label("每一次游玩，都留下新的眼光。\n体力上限翻倍至 %d，体力也已回满。" % PlayerState.max_energy, Vector2(45, 111), Vector2(558, 91), 23, Color("715584"))
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.add_child(message)
	var confirm := make_button("收好这份成长", Vector2(211, 232), Vector2(226, 52))
	confirm.pressed.connect(close_aesthetic_reward)
	letter.add_child(confirm)


func close_aesthetic_reward() -> void:
	if is_instance_valid(aesthetic_reward_overlay):
		aesthetic_reward_overlay.queue_free()
		aesthetic_reward_overlay = null


func update_layout() -> void:
	var scale_factor := minf(size.x / STAGE_SIZE.x, size.y / STAGE_SIZE.y)
	stage.scale = Vector2.ONE * scale_factor
	stage.position = (size - STAGE_SIZE * scale_factor) * 0.5


func make_label(value: String, at: Vector2, dimensions: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	return label


func make_button(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("644678"))
	button.add_theme_color_override("font_disabled_color", Color("745981"))
	button.add_theme_stylebox_override("normal", make_style(Color("fff0df"), Color("e5b6aa"), 19, 2))
	button.add_theme_stylebox_override("hover", make_style(Color("fff8ec"), Color("f2c39e"), 19, 3))
	button.add_theme_stylebox_override("disabled", make_style(Color("d9c3d9"), Color("bca2c2"), 19, 2))
	return button


func make_style(fill: Color, border: Color, radius: int, border_size: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_size)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.14, 0.08, 0.24, 0.32)
	style.shadow_size = 9
	style.shadow_offset = Vector2(7, 9)
	return style


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if is_instance_valid(aesthetic_reward_overlay):
			close_aesthetic_reward()
		elif launching:
			finish_play_story()
		else:
			SceneFade.change_to(BEDROOM_SCENE, -1.0)
