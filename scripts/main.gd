extends Node2D

signal card_choice_made(choice: int)

const LOBBY_SCENE := "res://scenes/lobby.tscn"
const BEDROOM_SCENE := "res://scenes/bedroom.tscn"
const CardCatalog := preload("res://scripts/card_catalog.gd")
const Negative := CardCatalog.Negative
const CardFace := preload("res://scripts/card_face.gd")
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const ExamDifficulty := preload("res://scripts/exam_difficulty.gd")
const MatchRewards := preload("res://scripts/match_rewards.gd")
const MATCH_REWARDS_SCENE := preload("res://scenes/match_rewards.tscn")
const MATCH_MUSIC_NAME := "MatchTransitionMusic"
const STARTING_HAND_SIZE := 5
const FINAL_TURN := 5
const TURN_DRAW_COUNT := 2
const STARTING_ENERGY := 3
const HEALTH_TRACK_IN_TEXTURE := Rect2(237.0, 291.0, 1794.0, 155.0)
const PROGRESS_TRACK_IN_TEXTURE := Rect2(390.0, 333.0, 1548.0, 129.0)
const METER_TRACK_CENTER_Y := 79.0
const MAX_HAND_SIZE := 9
const CARD_SIZE := Vector2(142, 199)
const HAND_HOME_OFFSET := Vector2(-355, -235)
const BOARD_SIZE := Vector2(1152, 648)
const SLOT_POSITIONS := [Vector2(183, 334), Vector2(369, 334), Vector2(510, 334), Vector2(658, 334), Vector2(800, 334)]
const SLOT_SIZES := [Vector2(172, 180), Vector2(130, 180), Vector2(132, 180), Vector2(142, 180), Vector2(170, 180)]
const SLOT_STATUS := {
	"blocked_until": ["BlockMark", "封锁", "普通卡牌无法在此卡槽使用。", Color("da625b")],
	"reinforced_until": ["RaiseMark", "强化", "在此槽打出的卡牌数值效果 ×1.5。", Color("dda334")],
	"delayed_until": ["DelayMark", "延迟", "在此槽打出的牌将在下回合开始时结算两次。", Color("b587f0")],
	"repeat_until": ["RepeatMark", "重复", "本回合可以在此槽再次出牌，每次照常支付费用。", Color("69c9c5")],
}

class DelayedPlay:
	var card_id: int
	var slot: Control
	var multiplier: float

	func _init(id: int, origin: Control, effect_multiplier: float) -> void:
		card_id = id
		slot = origin
		multiplier = effect_multiplier

var deck: Array[int] = []
var discard_pile: Array[int] = []
var played_discards: Array[int] = []
var hand: Array[int] = []
var delayed_plays: Array[DelayedPlay] = []
var next_turn_slot_locks: Dictionary[Control, int] = {}
var starting_energy_bonus := 0
var next_turn_energy_change := 0
var battle_card_sources: Dictionary[int, int] = {}
var free_cards: Dictionary[int, bool] = {}
var promise_draw_cards: Dictionary[int, bool] = {}
var card_discounts: Dictionary[int, int] = {}
var turn_end_progress_per_discard := 0.0
var discard_progress_bonuses: Dictionary[int, int] = {}
var end_turn_copies: Array[int] = []
var battle_cost_reduction := 0
var oath_applied := false
var energy := STARTING_ENERGY
var max_health := PlayerState.max_health
var health := float(max_health)
var progress := 0.0
var block := 0.0
var turn := 1
var hand_holder: Control
var card_preview: Control
var card_preview_tween: Tween
var slot_layer: Control
var selected_card: Control
var deck_choice_overlay: Control
var card_effect_resolving := false
var resolving_turn := false
var showing_turn_banner := false
var game_over := false
var match_settled := false
var match_rewards: MatchRewards
var end_button_tween: Tween
var health_fill: Panel
var block_fill: Panel
var health_track_width: float
var displayed_health := float(max_health)
var displayed_block := 0.0
var health_display_tween: Tween
var health_display_target := float(max_health)
var block_display_target := 0.0
var progress_fill: Panel
var progress_fill_tween: Tween
var progress_track_width: float
var hand_move_tween: Tween

@onready var match_music: AudioStreamPlayer = $MatchMusic
@onready var ui: Control = $HudLayer/UI
@onready var progress_value_label: Label = $HudLayer/UI/ProgressValueLabel
@onready var health_value_label: Label = $HudLayer/UI/HealthValueLabel
@onready var energy_value_label: Label = $HudLayer/UI/EnergyValueLabel
@onready var turn_value_label: Label = $HudLayer/UI/TurnValueLabel
@onready var end_button: Button = $HudLayer/UI/end
@onready var progress_target := ExamDifficulty.progress_target(PlayerState.passed_exams)
@onready var is_final_exam := RoundCalendar.is_final_exam(PlayerState.round_number)
@onready var turn_end_age_bonus := ExamDifficulty.turn_end_age_bonus(PlayerState.get_age_years())

var health_texture := preload("res://images/金色月桂叶游戏生命条.png")
var progress_texture := preload("res://images/米色网格便签进度条界面.png")
var energy_texture := preload("res://images/复古纸张能量徽章图标.png")
func _ready() -> void:
	if not prepare_match():
		return
	if get_tree().root.get_node_or_null(MATCH_MUSIC_NAME) == null:
		var music_stream := match_music.stream.duplicate() as AudioStreamMP3
		music_stream.loop = true
		match_music.stream = music_stream
		match_music.play()
	build_deck()
	draw_starting_hand()
	build_interface()
	var end_art := TextureRect.new()
	end_art.texture = load("res://images/ui/end_paper.png")
	end_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	end_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	end_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_button.add_child(end_art)
	var end_label := Label.new()
	end_label.text = "交卷"
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_color_override("font_color", Color("604374"))
	end_label.add_theme_font_size_override("font_size", 27)
	end_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	end_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	end_button.add_child(end_label)
	end_button.tooltip_text = "已达到目标，可以提前交卷"
	end_button.pivot_offset = end_button.size / 2.0
	end_button.mouse_entered.connect(set_end_button_hover.bind(true))
	end_button.mouse_exited.connect(set_end_button_hover.bind(false))
	end_button.pressed.connect(finish_game)
	await get_tree().process_frame
	animate_starting_hand()
	turn_value_label.text = "回合数：%d" % turn
	update_values()
	await show_turn_banner()


func prepare_match() -> bool:
	if PlayerState.final_exam_started:
		get_tree().change_scene_to_file.call_deferred(SceneFade.FINAL_EXAM_ENDING_SCENE)
		return false
	if not RoundCalendar.has_card_match(PlayerState.round_number):
		get_tree().change_scene_to_file.call_deferred(BEDROOM_SCENE)
		return false
	if not PlayerState.has_starter_deck():
		get_tree().change_scene_to_file.call_deferred(SceneFade.starter_deck_entry_scene())
		return false
	if is_final_exam:
		PlayerState.final_exam_started = true
		if not SaveManager.save_active_slot():
			PlayerState.final_exam_started = false
			show_final_exam_save_error()
			return false
	return true


func show_final_exam_save_error() -> void:
	game_over = true
	var notice := AcceptDialog.new()
	notice.title = "无法开始高考"
	notice.dialog_text = "无法记录开考状态，请检查存档目录后再试。"
	notice.ok_button_text = "返回准备界面"
	var go_back := get_tree().change_scene_to_file.bind(LOBBY_SCENE)
	notice.confirmed.connect(go_back)
	notice.canceled.connect(go_back)
	add_child(notice)
	notice.popup_centered.call_deferred(Vector2i(420, 160))


func _exit_tree() -> void:
	var transition_music := get_tree().root.get_node_or_null(MATCH_MUSIC_NAME) as AudioStreamPlayer
	if transition_music != null:
		transition_music.stop()
		transition_music.queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if game_over or card_effect_resolving or resolving_turn or showing_turn_banner:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		end_turn()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if SceneFade.curtain.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_J:
				if not SaveManager.debug_mode_enabled:
					return
				get_viewport().set_input_as_handled()
				if not is_final_exam:
					start_next_round()
				return
			KEY_ESCAPE:
				get_viewport().set_input_as_handled()
				if is_final_exam:
					return
				if match_settled:
					enter_next_round()
				else:
					get_tree().change_scene_to_file(LOBBY_SCENE)
				return
	if game_over or resolving_turn:
		return
	if selected_card != null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		cancel_selected_card()

func end_turn() -> void:
	if game_over or card_effect_resolving or resolving_turn or showing_turn_banner:
		return
	resolving_turn = true
	if selected_card != null:
		selected_card = null
		set_slots_selectable(false)
		rearrange_remaining_hand()
		await return_hand_to_player()
		if game_over:
			return
	for card_id in end_turn_copies:
		give_drawn_card(card_id)
	end_turn_copies.clear()
	var health_loss := turn_end_health_loss()
	for discard_index in held_negative_count(Negative.NOISE):
		discard_random_hand_card()
	progress += discard_pile.size() * turn_end_progress_per_discard
	if health_loss > 0:
		var absorbed := minf(block, health_loss)
		block -= absorbed
		health = maxf(0.0, health - (health_loss - absorbed))
		animate_health_display()
		if health_display_tween and health_display_tween.is_running():
			await health_display_tween.finished
	if game_over:
		return
	if health <= 0.0 or turn >= FINAL_TURN:
		settle_game(true)
		return
	turn += 1
	turn_value_label.text = "回合数：%d" % turn
	update_values()
	reset_used_slots()
	await show_turn_banner()
	if game_over:
		return
	apply_next_turn_slot_locks()
	await draw_turn_negative_card()
	if game_over:
		return
	energy = maxi(STARTING_ENERGY + starting_energy_bonus + next_turn_energy_change - held_negative_count(Negative.TIME_SHORTAGE), 0)
	next_turn_energy_change = 0
	var draw_count := maxi(TURN_DRAW_COUNT - held_negative_count(Negative.DISTRACTION), 0)
	update_values()
	var finish_after_start := await resolve_delayed_plays()
	if game_over:
		return
	await draw_cards(draw_count)
	if game_over:
		return
	if health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	block = 0.0
	update_values()
	if health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	resolving_turn = false
	if finish_after_start:
		end_turn.call_deferred()

func turn_end_health_loss() -> int:
	var loss := turn + turn_end_age_bonus
	for anxiety in held_negative_count(Negative.ANXIETY):
		loss *= 2
	return loss

func held_negative_count(card_id: int) -> int:
	var count := 0
	for held_card in hand:
		if source_card_id(held_card) == card_id:
			count += 1
	return count

func draw_turn_negative_card() -> void:
	var chance := ExamDifficulty.negative_draw_chance(health, max_health)
	if chance <= 0.0 or (chance < 1.0 and randf() >= chance):
		return
	await give_negative_card(Negative.values().pick_random())

func give_negative_card(card_id: int) -> void:
	var triggers_on_draw := CardCatalog.triggers_on_draw(card_id)
	var reveal_layer := Control.new()
	reveal_layer.name = "NegativeCardReveal"
	reveal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_layer.z_index = 55
	ui.add_child(reveal_layer)
	reveal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var shade := ColorRect.new()
	shade.color = Color(0.14, 0.025, 0.045, 0.66)
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_layer.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var card := create_card(card_id)
	var hover_area: Control = card.get_node("HoverArea")
	hover_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.scale = Vector2.ONE * 0.8
	card.modulate.a = 0.0
	card.position = (reveal_layer.size - card.size) * 0.5
	reveal_layer.add_child(card)

	var glow := Panel.new()
	var glow_style := StyleBoxFlat.new()
	glow_style.bg_color = Color(0.8, 0.2, 0.32, 0.2)
	glow_style.border_color = Color("f38d9b")
	glow_style.set_border_width_all(2)
	glow_style.set_corner_radius_all(7)
	glow_style.shadow_color = Color(0.9, 0.16, 0.32, 0.85)
	glow_style.shadow_size = 18
	glow.add_theme_stylebox_override("panel", glow_style)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.position = Vector2(-3, -3)
	glow.size = card.size + Vector2(6, 6)
	card.add_child(glow)
	card.move_child(glow, 0)

	var title := Label.new()
	title.text = "负面牌 · 立即生效" if triggers_on_draw else "抽到负面牌"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position.y = reveal_layer.size.y * 0.5 - card.size.y * 0.825 - 45.0
	title.size.x = reveal_layer.size.x
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.modulate.a = 0.0
	title.add_theme_font_size_override("font_size", 27)
	title.add_theme_color_override("font_color", Color("ffe0e3"))
	title.add_theme_color_override("font_outline_color", Color("4d111b"))
	title.add_theme_constant_override("outline_size", 6)
	reveal_layer.add_child(title)

	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(shade, "modulate:a", 1.0, 0.22)
	reveal.tween_property(title, "modulate:a", 1.0, 0.22)
	reveal.tween_property(card, "modulate:a", 1.0, 0.2)
	reveal.tween_property(card, "scale", Vector2.ONE * 1.65, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.chain().tween_interval(0.43)
	await reveal.finished
	if game_over:
		reveal_layer.queue_free()
		return
	var finish := create_tween().set_parallel(true)
	finish.tween_property(shade, "modulate:a", 0.0, 0.24)
	finish.tween_property(title, "modulate:a", 0.0, 0.22)
	if triggers_on_draw:
		match card_id:
			Negative.OVERDRAW:
				block_random_slot()
			Negative.EXAM_PRESSURE:
				consume_health(-int(CardCatalog.numbers(card_id)["health_change"]), true)
				animate_health_display()
		finish.tween_property(card, "modulate:a", 0.0, 0.24)
		await finish.finished
		if card_id == Negative.EXAM_PRESSURE and health_display_tween and health_display_tween.is_running():
			await health_display_tween.finished
	else:
		# Negative cards still take a place in a full hand.
		var hand_index := hand.size()
		var hand_count := hand_index + 1
		var destination := hand_holder.get_global_transform() * get_fan_position(hand_index, hand_count)
		finish.tween_property(card, "global_position", destination, 0.50).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		finish.tween_property(card, "rotation", get_fan_rotation(hand_index, hand_count), 0.50)
		finish.tween_property(card, "scale", Vector2.ONE, 0.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		finish.tween_property(glow, "modulate:a", 0.0, 0.18).set_delay(0.32)
		for index in hand_index:
			var held_card := hand_holder.get_child(index) as Control
			finish.tween_property(held_card, "position", get_fan_position(index, hand_count), 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			finish.tween_property(held_card, "rotation", get_fan_rotation(index, hand_count), 0.40)
		await finish.finished
		if not game_over:
			card.reparent(hand_holder)
			card.position = get_fan_position(hand_index, hand_count)
			hover_area.mouse_filter = Control.MOUSE_FILTER_STOP
			register_hand_card(card, card_id)
			glow.queue_free()
	reveal_layer.queue_free()

func show_turn_banner() -> void:
	showing_turn_banner = true
	var banner := Control.new()
	banner.size = Vector2(560, 112)
	banner.position = Vector2(-banner.size.x, (ui.size.y - banner.size.y) / 2.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 70
	ui.add_child(banner)
	var background := ColorRect.new()
	background.color = Color(0.10, 0.09, 0.16, 0.88)
	background.size = banner.size
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(background)
	var title := Label.new()
	title.text = "第 %d 回合开始" % turn
	title.size = banner.size
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1.0, 0.91, 0.7))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(title)
	var center_x := (ui.size.x - banner.size.x) / 2.0
	var tween := create_tween()
	tween.tween_property(banner, "position:x", center_x, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.65)
	tween.tween_property(banner, "position:x", ui.size.x, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	await tween.finished
	banner.queue_free()
	showing_turn_banner = false

func discard_random_hand_card() -> void:
	var candidates := discardable_hand_indices()
	if not candidates.is_empty():
		apply_hand_discard_effects([discard_hand_card(candidates.pick_random())])

func discardable_hand_indices() -> Array[int]:
	var indices: Array[int] = []
	for index in hand.size():
		if source_card_id(hand[index]) != Negative.RUSH:
			indices.append(index)
	return indices

func animate_card_to_deck(card: Control) -> void:
	card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.z_index = 56
	var target := ui.size * Vector2(0.88, 0.25) - card.size * 0.5
	var travel := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	travel.tween_property(card, "position", target, 0.42)
	travel.tween_property(card, "rotation", deg_to_rad(-15), 0.42)
	travel.tween_property(card, "scale", Vector2.ONE * 0.45, 0.42)
	travel.tween_property(card, "modulate:a", 0.0, 0.18).set_delay(0.24)
	await travel.finished
	card.queue_free()

func discard_hand_card(index: int, animate_layout: bool = true) -> int:
	var card: Control = hand_holder.get_child(index)
	if card_preview.visible:
		card_preview.hide()
	var discarded_id: int = hand.pop_at(index)
	if not CardCatalog.is_negative(source_card_id(discarded_id)):
		discard_pile.append(discarded_id)
	card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.reparent(ui, true)
	card.z_index = 45
	var discard_tween := create_tween().set_parallel(true)
	discard_tween.tween_property(card, "position", card.position + Vector2(260, -180), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	discard_tween.tween_property(card, "rotation", card.rotation + deg_to_rad(40), 0.6)
	discard_tween.tween_property(card, "scale", Vector2(0.55, 0.55), 0.6)
	discard_tween.tween_property(card, "modulate:a", 0.0, 0.6).set_delay(0.12)
	discard_tween.chain().tween_callback(card.queue_free)
	if not animate_layout:
		return discarded_id
	for card_index in hand_holder.get_child_count():
		var remaining: Control = hand_holder.get_child(card_index)
		remaining.set_meta("hand_index", card_index)
		remaining.z_index = card_index
		var layout_tween := create_tween().set_parallel(true)
		layout_tween.tween_property(remaining, "position", get_fan_position(card_index, hand.size()), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		layout_tween.tween_property(remaining, "rotation", get_fan_rotation(card_index, hand.size()), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return discarded_id

func discard_all_hand_cards() -> int:
	var discarded: Array[int] = []
	var candidates := discardable_hand_indices()
	candidates.reverse()
	for index in candidates:
		discarded.append(discard_hand_card(index, false))
	rearrange_remaining_hand()
	apply_hand_discard_effects(discarded)
	return discarded.size()

func apply_hand_discard_effects(discarded: Array[int]) -> void:
	if discarded.is_empty():
		return
	var piles: Array[Array] = [hand, deck, discard_pile]
	for pile in piles:
		for card_id: int in pile:
			var source := source_card_id(card_id)
			if PlayerState.card_base_id(source) == CardCatalog.FUSHIMI_LAST_BATTLE_CARD:
				var gain := int(PlayerState.card_numbers(source)["progress_per_discard"])
				discard_progress_bonuses[card_id] = discard_progress_bonuses.get(card_id, 0) + gain * discarded.size()
	for index in hand.size():
		var card_id := hand[index]
		if discard_progress_bonuses.has(card_id):
			set_battle_card_face(hand_holder.get_child(index).get_node("CardArt"), card_id)
	for card_id in discarded:
		var source := source_card_id(card_id)
		match PlayerState.card_base_id(source):
			CardCatalog.FUSHIMI_PEN_CARD:
				var reduction := int(PlayerState.card_numbers(source)["cost_reduction"])
				card_discounts[card_id] = card_discounts.get(card_id, 0) + reduction
				discard_pile.erase(card_id)
				give_drawn_card(card_id)
			CardCatalog.FUSHIMI_NIGHT_WALK_CARD:
				progress += int(PlayerState.card_numbers(source)["discard_progress"])
	update_values()

func prepare_draw() -> bool:
	if deck.is_empty() and not discard_pile.is_empty():
		# Played cards are already in discard_pile; played_discards only tracks their origin.
		deck.assign(discard_pile)
		discard_pile.clear()
		played_discards.clear()
		deck.shuffle()
	return not deck.is_empty()

func draw_cards(amount: int, zero_cost: bool = false) -> void:
	for draw_index in amount:
		if not prepare_draw():
			return
		var card_id: int = deck.pop_back()
		give_drawn_card(make_card_free(card_id) if zero_cost else card_id)
		await get_tree().create_timer(0.6).timeout

func give_drawn_card(drawn_card_id: int) -> void:
	if hand.size() >= MAX_HAND_SIZE:
		discard_pile.append(drawn_card_id)
		animate_discarded_draw(drawn_card_id)
		return
	add_card_to_hand(drawn_card_id, true)

func add_card_to_hand(card_id: int, animate_draw: bool = false) -> void:
	var new_card := create_card(card_id)
	new_card.position = Vector2(760, -330) if animate_draw else Vector2(284, 190)
	new_card.scale = Vector2(0.62, 0.62) if animate_draw else Vector2.ONE
	new_card.rotation = deg_to_rad(-18.0) if animate_draw else 0.0
	new_card.modulate.a = 0.75 if animate_draw else 0.0
	hand_holder.add_child(new_card)
	register_hand_card(new_card, card_id)

	for card_index in hand_holder.get_child_count():
		var card: Control = hand_holder.get_child(card_index)
		card.set_meta("hand_index", card_index)
		card.z_index = card_index
		var tween := create_tween().set_parallel(true)
		var duration := 0.58 if card == new_card and animate_draw else 0.38
		tween.tween_property(card, "position", get_fan_position(card_index, hand_holder.get_child_count()), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "rotation", get_fan_rotation(card_index, hand_holder.get_child_count()), duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		if card == new_card:
			tween.tween_property(card, "modulate:a", 1.0, 0.2)
			if animate_draw:
				tween.tween_property(card, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func register_hand_card(card: Control, card_id: int) -> void:
	var hand_index := hand.size()
	hand.append(card_id)
	card.set_meta("hand_index", hand_index)
	card.set_meta("card_id", card_id)
	card.z_index = hand_index
	connect_card_interaction(card)

func animate_discarded_draw(card_id: int) -> void:
	var discarded_card := create_card(card_id)
	discarded_card.set_meta("card_id", card_id)
	discarded_card.position = Vector2(505, 330)
	discarded_card.z_index = 25
	discarded_card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(discarded_card)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(discarded_card, "position", Vector2(1000, 125), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(discarded_card, "rotation", deg_to_rad(32.0), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(discarded_card, "scale", Vector2(0.45, 0.45), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(discarded_card, "modulate:a", 0.0, 0.6)
	tween.set_parallel(false)
	tween.tween_callback(discarded_card.queue_free)

func connect_card_interaction(card: Control) -> void:
	var hover_area: Control = card.get_node("HoverArea")
	hover_area.mouse_entered.connect(show_card_preview.bind(card))
	hover_area.mouse_exited.connect(hide_card_preview.bind(card))
	hover_area.gui_input.connect(select_card_from_hand.bind(card))

func block_random_slot() -> void:
	var available_slots: Array[Control] = []
	for slot: Control in slot_layer.get_children():
		if not is_slot_blocked(slot):
			available_slots.append(slot)
	if available_slots.is_empty():
		return
	var slot: Control = available_slots.pick_random()
	slot.set_meta("blocked", true)
	refresh_slot_statuses(slot)
	animate_slot_status(slot, slot.get_node("BlockMark"), SLOT_STATUS["blocked_until"][3])

func has_usable_slot() -> bool:
	for slot: Control in slot_layer.get_children():
		if can_use_slot(slot):
			return true
	return false

func is_slot_blocked(slot: Control) -> bool:
	return bool(slot.get_meta("blocked")) or int(slot.get_meta("blocked_until", 0)) >= turn

func can_use_slot(slot: Control) -> bool:
	if bool(slot.get_meta("used")) and int(slot.get_meta("repeat_until", 0)) < turn:
		return false
	if selected_card != null and PlayerState.card_base_id(source_card_id(int(selected_card.get_meta("card_id")))) == 8:
		return is_slot_blocked(slot)
	return not is_slot_blocked(slot)

func build_deck() -> void:
	deck.assign(PlayerState.card_deck)
	for index in deck.size():
		var card_id := deck[index]
		match PlayerState.card_base_id(card_id):
			CardCatalog.FUSHIMI_PEN_CARD, CardCatalog.FUSHIMI_LAST_BATTLE_CARD:
				deck[index] = identify_card_copy(card_id)
	deck.shuffle()

func make_card_free(card_id: int) -> int:
	if battle_card_cost(card_id) == 0:
		return card_id
	var copy_id := identify_card_copy(card_id)
	free_cards[copy_id] = true
	return copy_id

func identify_card_copy(card_id: int) -> int:
	if battle_card_sources.has(card_id):
		return card_id
	# Store effects on individual copies using IDs that exist only in this match.
	var copy_id := -battle_card_sources.size() - 1
	battle_card_sources[copy_id] = card_id
	return copy_id

func source_card_id(card_id: int) -> int:
	return battle_card_sources.get(card_id, card_id)

func battle_card_cost(card_id: int) -> int:
	if free_cards.has(card_id):
		return 0
	var source := source_card_id(card_id)
	var discount: int = battle_cost_reduction + card_discounts.get(card_id, 0)
	if PlayerState.card_base_id(source) == CardCatalog.SHIRAKAWA_SNOW_CARD:
		discount += discard_pile.size()
	return maxi(0, PlayerState.card_cost(source) - discount)

func battle_card_numbers(card_id: int) -> Dictionary:
	var values := PlayerState.card_numbers(source_card_id(card_id))
	if discard_progress_bonuses.has(card_id):
		values["progress"] += discard_progress_bonuses[card_id]
	return values

func set_battle_card_face(face: CardFace, card_id: int) -> void:
	var source := source_card_id(card_id)
	var current_cost := battle_card_cost(card_id)
	face.set_card(source, battle_card_numbers(card_id), current_cost if current_cost != PlayerState.card_cost(source) else -1)
	var marker := face.get_node_or_null("PromiseDraw") as Label
	var marked := promise_draw_cards.has(card_id)
	if marked and marker == null:
		marker = Label.new()
		marker.name = "PromiseDraw"
		marker.text = "约定 · 使用时抽一张"
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		marker.add_theme_color_override("font_color", Color("fff1f9"))
		marker.add_theme_color_override("font_outline_color", Color("65407a"))
		marker.add_theme_constant_override("outline_size", 6)
		face.add_child(marker)
		marker.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		marker.offset_top = -30.0
		marker.offset_bottom = -5.0
	if marker != null:
		marker.visible = marked

func draw_starting_hand() -> void:
	hand.clear()
	for card_index in STARTING_HAND_SIZE:
		if not prepare_draw():
			break
		hand.append(deck.pop_back())

func build_interface() -> void:
	create_progress_ui(ui)
	create_health_ui(ui)
	create_energy_ui(ui)
	create_card_slots(ui)
	create_hand_ui(ui)

func create_progress_ui(parent: Control) -> void:
	var meter := TextureRect.new()
	meter.texture = progress_texture
	meter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meter.set_anchors_preset(Control.PRESET_CENTER_TOP)
	meter.position.x = -210
	meter.size = Vector2(420, 140)
	meter.z_index = 20
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(meter)
	var track := get_meter_track(meter, PROGRESS_TRACK_IN_TEXTURE)
	meter.position.y = METER_TRACK_CENTER_Y - track.get_center().y
	progress_track_width = track.size.x
	progress_fill = make_rounded_meter_fill(Color(0.96, 0.64, 0.25, 0.82), track)
	meter.add_child(progress_fill)

	progress_value_label.text = "%s / %d" % [format_value(progress), progress_target]

func create_health_ui(parent: Control) -> void:
	var holder := Control.new()
	holder.position.x = 24
	holder.size = Vector2(330, 110)
	holder.z_index = 20
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)

	var bar := TextureRect.new()
	bar.texture = health_texture
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bar.size = Vector2(330, 110)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bar)

	var track := get_meter_track(bar, HEALTH_TRACK_IN_TEXTURE)
	holder.position.y = METER_TRACK_CENTER_Y - track.get_center().y
	health_track_width = track.size.x
	health_fill = make_rounded_meter_fill(Color("b9363e"), track)
	health_fill.name = "HealthFill"
	holder.add_child(health_fill)

	block_fill = make_rounded_meter_fill(Color("438de0"), track)
	block_fill.name = "BlockFill"
	holder.add_child(block_fill)

	refresh_health_display()

func get_meter_track(meter: TextureRect, track_in_texture: Rect2) -> Rect2:
	var texture_size := meter.texture.get_size()
	var texture_scale := minf(meter.size.x / texture_size.x, meter.size.y / texture_size.y)
	var texture_origin := (meter.size - texture_size * texture_scale) * 0.5
	return Rect2(texture_origin + track_in_texture.position * texture_scale, track_in_texture.size * texture_scale)

func make_rounded_meter_fill(fill_color: Color, track: Rect2) -> Panel:
	var fill := Panel.new()
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.set_corner_radius_all(roundi(track.size.y * 0.5))
	fill.add_theme_stylebox_override("panel", style)
	fill.position = track.position
	fill.size = Vector2(0.0, track.size.y)
	return fill

func create_energy_ui(parent: Control) -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	holder.position = Vector2(-190, -157)
	holder.size = Vector2(166, 120)
	holder.z_index = 20
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)

	var badge := TextureRect.new()
	badge.texture = energy_texture
	badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	badge.size = holder.size
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(badge)

	energy_value_label.text = str(energy)

func create_hand_ui(parent: Control) -> void:
	hand_holder = Control.new()
	hand_holder.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hand_holder.position = HAND_HOME_OFFSET
	hand_holder.size = Vector2(710, 205)
	hand_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hand_holder.z_index = 2
	parent.add_child(hand_holder)

	for card_index in hand.size():
		var card := create_card(hand[card_index])
		card.position = Vector2(284, -82)
		card.modulate.a = 0.0
		card.set_meta("hand_index", card_index)
		card.set_meta("card_id", hand[card_index])
		card.z_index = card_index
		connect_card_interaction(card)
		hand_holder.add_child(card)

	create_card_preview(parent)

func animate_starting_hand() -> void:
	for card in hand_holder.get_children():
		var card_index: int = card.get_meta("hand_index")
		var target_position := get_fan_position(card_index, hand.size())
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(card, "modulate:a", 1.0, 0.12).set_delay(card_index * 0.18)
		tween.tween_property(card, "position", target_position, 0.42).set_delay(card_index * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(card, "rotation", get_fan_rotation(card_index, hand.size()), 0.42).set_delay(card_index * 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func get_fan_position(card_index: int, card_count: int) -> Vector2:
	var fan_offset := card_index - (card_count - 1) / 2.0
	var intervals: int = maxi(card_count - 1, 1)
	var spacing: float = minf(CARD_SIZE.x, (hand_holder.size.x - CARD_SIZE.x) / float(intervals))
	var first_x := (hand_holder.size.x - CARD_SIZE.x - (card_count - 1) * spacing) / 2.0
	return Vector2(first_x + card_index * spacing, abs(fan_offset) * 12)

func get_fan_rotation(card_index: int, card_count: int) -> float:
	var intervals: int = maxi(card_count - 1, 1)
	var rotation_step: float = minf(5.0, 22.0 / float(intervals))
	return deg_to_rad((card_index - (card_count - 1) / 2.0) * rotation_step)

func create_card(card_id: int) -> Control:
	var card_root := Control.new()
	card_root.size = CARD_SIZE
	card_root.pivot_offset = CARD_SIZE / 2.0
	card_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var art := CardFace.new()
	art.name = "CardArt"
	set_battle_card_face(art, card_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.size = CARD_SIZE
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_root.add_child(art)

	var hover_area := Control.new()
	hover_area.name = "HoverArea"
	hover_area.size = CARD_SIZE * 0.4
	hover_area.position = (CARD_SIZE - hover_area.size) / 2.0
	hover_area.mouse_filter = Control.MOUSE_FILTER_STOP
	card_root.add_child(hover_area)
	return card_root

func create_card_slots(parent: Control) -> void:
	slot_layer = Control.new()
	slot_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot_layer.z_index = 0
	parent.add_child(slot_layer)

	for slot_index in SLOT_POSITIONS.size():
		var slot := Control.new()
		slot.name = "CardSlot%d" % (slot_index + 1)
		var slot_start: Vector2 = SLOT_POSITIONS[slot_index] / BOARD_SIZE
		var slot_end: Vector2 = (SLOT_POSITIONS[slot_index] + SLOT_SIZES[slot_index]) / BOARD_SIZE
		slot.anchor_left = slot_start.x
		slot.anchor_top = slot_start.y
		slot.anchor_right = slot_end.x
		slot.anchor_bottom = slot_end.y
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_meta("blocked", false)
		slot.set_meta("blocked_until", 0)
		slot.set_meta("reinforced_until", 0)
		slot.set_meta("delayed_until", 0)
		slot.set_meta("used", false)
		slot.gui_input.connect(use_selected_card.bind(slot))
		slot_layer.add_child(slot)

		var glow := ColorRect.new()
		glow.name = "Glow"
		glow.size = Vector2(96, 112)
		glow.set_anchors_preset(Control.PRESET_CENTER)
		glow.position = -glow.size / 2.0
		glow.color = Color.WHITE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.material = make_center_glow_material()
		glow.hide()
		slot.add_child(glow)

		for status: String in SLOT_STATUS:
			var definition: Array = SLOT_STATUS[status]
			var marker := Label.new()
			marker.name = definition[0]
			marker.text = definition[1]
			marker.size = Vector2(60, 27)
			marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			marker.add_theme_font_size_override("font_size", 20)
			marker.add_theme_color_override("font_color", definition[3].lightened(0.35))
			marker.add_theme_color_override("font_outline_color", Color("36273f"))
			marker.add_theme_constant_override("outline_size", 6)
			marker.mouse_filter = Control.MOUSE_FILTER_PASS
			marker.hide()
			slot.add_child(marker)

func refresh_slot_statuses(slot: Control) -> void:
	var badge_index := 0
	for status: String in SLOT_STATUS:
		var definition: Array = SLOT_STATUS[status]
		var marker: Label = slot.get_node(definition[0])
		var remaining := int(slot.get_meta(status, 0)) - turn + 1
		var permanent := status == "blocked_until" and bool(slot.get_meta("blocked"))
		if not permanent and remaining <= 0:
			if marker.visible:
				stop_slot_status_animation(slot, marker)
				marker.hide()
			continue
		var duration := "直到解封" if permanent else "剩余 %d 回合" % remaining
		marker.tooltip_text = "%s\n%s\n%s" % [definition[1], definition[2], duration]
		marker.position = Vector2(4 + (badge_index % 2) * 61, -28 + floori(badge_index * 0.5) * 25)
		marker.show()
		badge_index += 1

func grant_slot_status(slot: Control, status: String, duration: int) -> void:
	slot.set_meta(status, turn + duration - 1)
	refresh_slot_statuses(slot)
	var definition: Array = SLOT_STATUS[status]
	animate_slot_status(slot, slot.get_node(definition[0]), definition[3], 2 if status == "delayed_until" else 1)

func apply_next_turn_slot_locks() -> void:
	for slot: Control in next_turn_slot_locks:
		grant_slot_status(slot, "blocked_until", next_turn_slot_locks[slot])
	next_turn_slot_locks.clear()


func make_center_glow_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	float distance_to_center = length((UV - vec2(0.5)) * vec2(1.0, 0.9));
	float glow = 1.0 - smoothstep(0.05, 0.5, distance_to_center);
	COLOR = vec4(1.0, 0.82, 0.35, glow * 0.72);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material

func select_card_from_hand(event: InputEvent, card: Control) -> void:
	if game_over or showing_turn_banner or resolving_turn or card_effect_resolving or selected_card != null or not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var card_id: int = card.get_meta("card_id")
	if energy < battle_card_cost(card_id):
		return
	selected_card = card
	if not has_usable_slot():
		selected_card = null
		return
	UiSounds.play_click()
	card.get_node("HoverArea").accept_event()
	hide_card_preview(card)
	for hand_card in hand_holder.get_children():
		hand_card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_IGNORE
	await move_hand_below_screen()
	if selected_card != card:
		return
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		await get_tree().process_frame
	if selected_card == card and has_usable_slot():
		set_slots_selectable(true)

func cancel_selected_card() -> void:
	selected_card = null
	set_slots_selectable(false)
	if hand_move_tween and hand_move_tween.is_running():
		await hand_move_tween.finished
	await return_hand_to_player()

func reset_used_slots() -> void:
	for slot: Control in slot_layer.get_children():
		slot.set_meta("used", false)
		refresh_slot_statuses(slot)


func stop_slot_status_animation(slot: Control, marker: Control) -> void:
	if marker.has_meta("status_tween"):
		var tween: Tween = marker.get_meta("status_tween")
		tween.kill()
		marker.remove_meta("status_tween")
	var pulse := slot.get_node_or_null(NodePath("%sPulse" % marker.name))
	if pulse != null:
		slot.remove_child(pulse)
		pulse.queue_free()

func animate_slot_status(slot: Control, marker: Control, color: Color, pulse_count: int = 1) -> void:
	stop_slot_status_animation(slot, marker)
	marker.pivot_offset = marker.size * 0.5
	marker.modulate.a = 1.0
	marker.scale = Vector2.ONE * 1.4
	marker.show()

	var pulse := Control.new()
	pulse.name = "%sPulse" % marker.name
	pulse.position = slot.size * 0.5
	pulse.z_index = 15
	pulse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(pulse)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.12)
	style.border_color = color.lightened(0.2)
	style.shadow_color = Color(color, 0.55)
	style.shadow_size = 8
	style.set_border_width_all(3)
	style.set_corner_radius_all(80)

	var tween := marker.create_tween().set_parallel(true)
	marker.set_meta("status_tween", tween)
	tween.tween_property(marker, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for pulse_index in pulse_count:
		var ring := Panel.new()
		ring.size = Vector2.ONE * minf(slot.size.x, slot.size.y) * 0.72
		ring.pivot_offset = ring.size * 0.5
		ring.position = -ring.pivot_offset
		ring.scale = Vector2.ONE * 0.42
		ring.modulate.a = 0.0
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.add_theme_stylebox_override("panel", style)
		pulse.add_child(ring)
		var delay := pulse_index * 0.13
		tween.tween_property(ring, "scale", Vector2.ONE * 1.42, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(delay)
		tween.tween_property(ring, "modulate:a", 0.0, 0.40).from(1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(delay)
	tween.finished.connect(pulse.queue_free)

func return_hand_to_player() -> void:
	hand_move_tween = create_tween()
	hand_move_tween.tween_method(set_hand_bottom_offset, hand_holder.offset_top, HAND_HOME_OFFSET.y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await hand_move_tween.finished
	for hand_card in hand_holder.get_children():
		hand_card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_STOP

func move_hand_below_screen() -> void:
	if hand_move_tween and hand_move_tween.is_running():
		hand_move_tween.kill()
	# Move far enough for the entire card, including its rotation, to leave the viewport.
	var offscreen_offset := CARD_SIZE.y + 40.0
	hand_move_tween = create_tween()
	hand_move_tween.tween_method(set_hand_bottom_offset, hand_holder.offset_top, offscreen_offset, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hand_move_tween.finished

func set_hand_bottom_offset(offset: float) -> void:
	hand_holder.position.y = ui.size.y + offset

func set_slots_selectable(enabled: bool) -> void:
	for slot in slot_layer.get_children():
		var selectable: bool = enabled and selected_card != null and can_use_slot(slot)
		slot.mouse_filter = Control.MOUSE_FILTER_STOP if selectable else Control.MOUSE_FILTER_IGNORE
		var glow: ColorRect = slot.get_node("Glow")
		if slot.has_meta("flash_tween"):
			var previous_tween: Tween = slot.get_meta("flash_tween")
			if is_instance_valid(previous_tween):
				previous_tween.kill()
		if selectable:
			glow.show()
			glow.modulate.a = 1.0
			var tween := create_tween().set_loops()
			tween.tween_property(glow, "modulate:a", 0.12, 0.42)
			tween.tween_property(glow, "modulate:a", 1.0, 0.42)
			slot.set_meta("flash_tween", tween)
		else:
			glow.hide()

func use_selected_card(event: InputEvent, slot: Control) -> bool:
	if game_over or card_effect_resolving or resolving_turn or selected_card == null or not (event is InputEventMouseButton):
		return false
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return false
	if slot.mouse_filter != Control.MOUSE_FILTER_STOP or not can_use_slot(slot):
		return false
	UiSounds.play_click()

	var used_card := selected_card
	var card_id: int = used_card.get_meta("card_id")
	var multiplier := 1.5 if int(slot.get_meta("reinforced_until")) >= turn else 1.0
	var is_delayed := int(slot.get_meta("delayed_until")) >= turn
	card_effect_resolving = true
	energy -= battle_card_cost(card_id)
	hand.remove_at(int(used_card.get_meta("hand_index")))
	slot.set_meta("used", true)
	selected_card = null
	set_slots_selectable(false)
	if is_delayed:
		delayed_plays.append(DelayedPlay.new(card_id, slot, multiplier))
	update_values()
	await animate_card_play(used_card, slot)
	rearrange_remaining_hand()
	await return_hand_to_player()
	var finish_turn := false
	if not is_delayed:
		finish_turn = await resolve_play(card_id, slot, multiplier, 1)
	card_effect_resolving = false
	if finish_turn and not game_over:
		end_turn()
	return true

func animate_card_play(card: Control, slot: Control) -> void:
	# The hand is hidden during slot selection. Launch from its visible resting position.
	var start := Vector2(ui.size.x * 0.5, ui.size.y) + HAND_HOME_OFFSET + card.position
	var center := slot.global_position - ui.global_position + slot.size * 0.5
	var destination := center - card.pivot_offset
	var landing_scale := minf(slot.size.x / card.size.x, slot.size.y / card.size.y) * 0.88
	card.reparent(ui, false)
	card.position = start
	card.z_index = 25
	card.modulate.a = 0.0
	card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_IGNORE

	var flight := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	flight.tween_method(func(weight: float) -> void:
		card.position = start.lerp(destination, weight) + Vector2.UP * sin(weight * PI) * 44.0
	, 0.0, 1.0, 0.28)
	flight.tween_property(card, "rotation", 0.0, 0.28)
	flight.tween_property(card, "scale", Vector2.ONE * landing_scale, 0.28)
	flight.tween_property(card, "modulate:a", 1.0, 0.08)
	await flight.finished

	var impact := Panel.new()
	impact.name = "CardPlayImpact"
	impact.size = card.size * landing_scale + Vector2(16.0, 16.0)
	impact.pivot_offset = impact.size * 0.5
	impact.position = center - impact.pivot_offset
	impact.scale = Vector2.ONE * 0.88
	impact.z_index = 24
	impact.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.82, 0.47, 0.20)
	style.border_color = Color("ffe5a6")
	style.shadow_color = Color(1.0, 0.70, 0.28, 0.58)
	style.shadow_size = 12
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	impact.add_theme_stylebox_override("panel", style)
	ui.add_child(impact)

	var settle := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	settle.tween_property(impact, "scale", Vector2.ONE * 1.24, 0.26)
	settle.tween_property(impact, "modulate:a", 0.0, 0.22).set_delay(0.04)
	settle.tween_property(card, "scale", Vector2.ONE * landing_scale * 0.9, 0.16).set_delay(0.08)
	settle.tween_property(card, "modulate:a", 0.0, 0.16).set_delay(0.08)
	settle.chain().tween_callback(card.queue_free)
	settle.tween_callback(impact.queue_free)

func resolve_delayed_plays() -> bool:
	var due_plays := delayed_plays.duplicate()
	delayed_plays.clear()
	var finish_turn := false
	for play in due_plays:
		if game_over:
			break
		var ends_turn := await resolve_play(play.card_id, play.slot, play.multiplier, 2)
		finish_turn = finish_turn or ends_turn
	return finish_turn

func resolve_play(card_id: int, slot: Control, multiplier: float, repetitions: int) -> bool:
	var finish_turn := false
	for repetition in repetitions:
		var ends_turn := await apply_card_effect(card_id, slot, multiplier)
		finish_turn = finish_turn or ends_turn
		if game_over:
			break
		if promise_draw_cards.has(card_id):
			await draw_cards(1)
	if not CardCatalog.exhausts_on_play(PlayerState.card_base_id(source_card_id(card_id))) and (not oath_applied or battle_card_cost(card_id) == 0):
		discard_pile.append(card_id)
		played_discards.append(card_id)
	update_values()
	return finish_turn

func apply_card_effect(card_id: int, slot: Control, multiplier: float) -> bool:
	var source := source_card_id(card_id)
	var values := battle_card_numbers(card_id)
	match PlayerState.card_base_id(source):
		0:
			await draw_cards(roundi(int(values["draw"]) * multiplier))
		1:
			progress += int(values["progress"]) * multiplier
		2:
			block += int(values["block"]) * multiplier
		3:
			progress += int(values["progress"]) * multiplier
		4:
			health = minf(max_health, health + int(values["heal"]) * multiplier)
			block += int(values["block"]) * multiplier
		5:
			grant_slot_status(slot, "reinforced_until", int(values["duration"]))
		6:
			var health_change := int(values["health_change"]) * multiplier
			if health_change < 0.0:
				consume_health(-health_change)
			else:
				health = minf(max_health, health + health_change)
			if not game_over:
				progress += int(values["progress"]) * multiplier
		7:
			progress += int(values["progress"]) * multiplier
			update_values()
			for pick in int(values["pick"]):
				if not prepare_draw():
					break
				var chosen := await request_card_choice(deck, false)
				deck.erase(chosen)
				give_drawn_card(chosen)
				await get_tree().create_timer(0.6).timeout
		8:
			unblock_slot(slot)
			health = minf(max_health, health + int(values["heal"]) * multiplier)
			block += int(values["block"]) * multiplier
		9:
			var targets: Array[Control] = []
			for target: Control in slot_layer.get_children():
				if target != slot and not is_slot_blocked(target):
					targets.append(target)
			if not targets.is_empty():
				var target: Control = targets.pick_random()
				grant_slot_status(target, "blocked_until", int(values["duration"]))
			progress += int(values["progress"]) * multiplier
		10:
			health = minf(max_health, health + int(values["heal"]) * multiplier)
		11:
			progress += int(values["progress"]) * multiplier
		12:
			var requested := int(values["discard"])
			if discardable_hand_indices().size() >= requested:
				await choose_and_discard_cards(requested)
				await draw_cards(roundi(int(values["draw"]) * multiplier))
		13:
			progress += int(values["progress"]) * multiplier
			update_values()
			await draw_cards(roundi(int(values["draw"]) * multiplier))
			await choose_and_discard_cards(int(values["discard"]))
		14:
			grant_slot_status(slot, "delayed_until", int(values["duration"]))
		15:
			health = minf(max_health, health + int(values["heal"]) * multiplier)
			update_values()
			await draw_cards(roundi(int(values["draw"]) * multiplier))
		16:
			progress += int(values["progress"]) * multiplier
			block += int(values["block"]) * multiplier
			update_values()
			await draw_cards(roundi(int(values["draw"]) * multiplier))
		17:
			for target: Control in slot_layer.get_children():
				if is_slot_blocked(target):
					block += int(values["block"]) * multiplier
					unblock_slot(target)
		18:
			progress += int(values["progress"]) * multiplier
			update_values()
			await draw_cards(roundi(int(values["draw"]) * multiplier))
		19:
			health = minf(max_health, int(values["health_set"]))
		20:
			if discard_all_hand_cards() > 0:
				await get_tree().create_timer(0.55).timeout
			await draw_cards(roundi(int(values["draw"]) * multiplier))
		21:
			energy += roundi(int(values["energy_gain"]) * multiplier)
			next_turn_energy_change += roundi(int(values["next_energy_change"]) * multiplier)
		22, CardCatalog.YUE_GOLDFISH_CARD:
			slot.set_meta("blocked", true)
			refresh_slot_statuses(slot)
			animate_slot_status(slot, slot.get_node("BlockMark"), SLOT_STATUS["blocked_until"][3])
			starting_energy_bonus += roundi(int(values["starting_energy_gain"]) * multiplier)
		23:
			next_turn_energy_change += roundi(int(values["next_energy_gain"]) * multiplier)
			next_turn_slot_locks[slot] = maxi(next_turn_slot_locks.get(slot, 0), int(values["duration"]))
		24:
			await recover_played_cards(1)
		25:
			await draw_cards(roundi(int(values["draw"]) * multiplier), true)
		26:
			energy += roundi(int(values["energy_gain"]) * multiplier)
		27:
			var health_change := hand.size() * int(values["health_per_hand"]) * multiplier
			if health_change < 0.0:
				consume_health(-health_change)
			else:
				health = minf(max_health, health + health_change)
			if not game_over:
				update_values()
				await draw_cards(roundi(int(values["draw"]) * multiplier))
		CardCatalog.YUE_FIRST_CARD:
			grant_slot_status(slot, "repeat_until", int(values["duration"]))
		CardCatalog.YUE_EMPTY_FISHBOWL_CARD:
			await recover_played_cards(2, int(values["recover_max_cost"]))
		CardCatalog.YUE_OATH_CARD:
			apply_oath(roundi(int(values["cost_reduction"]) * multiplier))
		CardCatalog.YUE_FINAL_PROMISE_CARD:
			grant_final_promise()
		CardCatalog.FUSHIMI_PEN_CARD, CardCatalog.FUSHIMI_LAST_BATTLE_CARD:
			progress += int(values["progress"]) * multiplier
		CardCatalog.FUSHIMI_TUTORING_CARD:
			var discarded_cost := await choose_and_discard_cards(2)
			health = minf(max_health, health + discarded_cost * multiplier)
		CardCatalog.FUSHIMI_NIGHT_WALK_CARD:
			progress += int(values["progress"]) * multiplier
			end_turn_copies.append(source)
		CardCatalog.FUSHIMI_TOGETHER_CARD:
			var discarded := discard_all_hand_cards()
			if discarded > 0:
				await get_tree().create_timer(0.55).timeout
				await draw_cards(roundi(discarded * multiplier))
		CardCatalog.SHIRAKAWA_GAME_CARD:
			for index in mini(deck.size(), roundi(int(values["mill"]) * multiplier)):
				discard_pile.append(deck.pop_back())
			if not discard_pile.is_empty() and hand.size() < MAX_HAND_SIZE:
				var chosen := await request_card_choice(discard_pile, false, "从弃牌区选择一张牌加入手牌")
				discard_pile.erase(chosen)
				played_discards.erase(chosen)
				give_drawn_card(chosen)
		CardCatalog.SHIRAKAWA_FAVOR_CARD:
			energy = 0
			var minimum_cost := int(values["minimum_cost"])
			var candidates := discard_pile.filter(func(id: int) -> bool: return battle_card_cost(id) >= minimum_cost)
			deck.append_array(discard_pile)
			if not discard_pile.is_empty():
				deck.shuffle()
			discard_pile.clear()
			played_discards.clear()
			update_values()
			if not candidates.is_empty():
				var chosen := await request_card_choice(candidates, false, "选择一张花费至少为 %d 的牌，降至 0 费并置于卡组顶" % minimum_cost)
				deck.erase(chosen)
				var free_card := make_card_free(chosen)
				deck.append(free_card)
				var returning_card := create_card(free_card)
				returning_card.position = (ui.size - returning_card.size) * 0.5
				ui.add_child(returning_card)
				await animate_card_to_deck(returning_card)
		CardCatalog.SHIRAKAWA_PUPPY_CARD:
			turn_end_progress_per_discard += int(values["turn_end_progress_per_card"]) * multiplier
		CardCatalog.SHIRAKAWA_OSMANTHUS_CARD:
			var reduction := roundi(int(values["cost_reduction"]) * multiplier)
			while not deck.is_empty():
				var copy_id := identify_card_copy(deck.pop_back())
				card_discounts[copy_id] = card_discounts.get(copy_id, 0) + reduction
				discard_pile.append(copy_id)
		CardCatalog.SHIRAKAWA_SNOW_CARD:
			progress = maxf(progress, progress_target)
			settle_game(true)
		Negative.ANXIETY, Negative.DISTRACTION, Negative.NOISE:
			consume_health(-int(values["health_change"]) * multiplier, true)
		Negative.TIME_SHORTAGE:
			energy = maxi(0, energy + roundi(int(values["energy_gain"]) * multiplier))
		Negative.RUSH:
			progress += int(values["progress"]) * multiplier
			block_random_slot()
			consume_health(-int(values["health_change"]) * multiplier, true)
	update_values()
	return false

func grant_final_promise() -> void:
	var piles: Array[Array] = [hand, deck, discard_pile]
	var candidates: Array[Vector2i] = []
	for pile_index in piles.size():
		for index in piles[pile_index].size():
			if not promise_draw_cards.has(piles[pile_index][index]):
				candidates.append(Vector2i(pile_index, index))
	candidates.shuffle()
	for location: Vector2i in candidates.slice(0, 5):
		var card_id: int = piles[location.x][location.y]
		var copy_id := identify_card_copy(card_id)
		piles[location.x][location.y] = copy_id
		promise_draw_cards[copy_id] = true
		if location.x == 0:
			var card := hand_holder.get_child(location.y)
			card.set_meta("card_id", copy_id)
			set_battle_card_face(card.get_node("CardArt") as CardFace, copy_id)
		elif location.x == 2:
			var index := played_discards.find(card_id)
			if index >= 0:
				played_discards[index] = copy_id

func apply_oath(cost_reduction: int) -> void:
	oath_applied = true
	battle_cost_reduction += cost_reduction
	var keep_card := func(card_id: int) -> bool: return battle_card_cost(card_id) == 0
	deck.assign(deck.filter(keep_card))
	discard_pile.assign(discard_pile.filter(keep_card))
	played_discards.assign(played_discards.filter(keep_card))
	for index in range(hand.size() - 1, -1, -1):
		var card := hand_holder.get_child(index)
		if keep_card.call(hand[index]):
			set_battle_card_face(card.get_node("CardArt") as CardFace, hand[index])
		else:
			hand.remove_at(index)
			hand_holder.remove_child(card)
			card.queue_free()
	card_preview.hide()
	rearrange_remaining_hand()

func recover_played_cards(amount: int, maximum_cost: int = -1) -> void:
	var candidates := played_discards.duplicate()
	if maximum_cost >= 0:
		candidates = candidates.filter(func(card_id: int) -> bool: return battle_card_cost(card_id) <= maximum_cost)
	var count := mini(amount, mini(candidates.size(), MAX_HAND_SIZE - hand.size()))
	for pick in count:
		var prompt := "选择一张打出过的牌加入手牌"
		if maximum_cost >= 0:
			prompt = "取回已打出的牌（花费 ≤ %d）  %d/%d" % [maximum_cost, pick + 1, count]
		var chosen := await request_card_choice(candidates, false, prompt)
		candidates.erase(chosen)
		discard_pile.erase(chosen)
		played_discards.erase(chosen)
		give_drawn_card(chosen)
		await get_tree().create_timer(0.6).timeout

func choose_and_discard_cards(amount: int) -> int:
	var discarded: Array[int] = []
	var total_cost := 0
	for pick in mini(amount, discardable_hand_indices().size()):
		var index := await request_card_choice(hand, true)
		total_cost += battle_card_cost(hand[index])
		discarded.append(discard_hand_card(index))
		await get_tree().create_timer(0.4).timeout
	apply_hand_discard_effects(discarded)
	return total_cost

func unblock_slot(slot: Control) -> void:
	slot.set_meta("blocked", false)
	slot.set_meta("blocked_until", 0)
	refresh_slot_statuses(slot)

func consume_health(amount: float, bypass_block: bool = false) -> void:
	var damage := maxf(amount, 0.0)
	var absorbed := 0.0 if bypass_block else minf(block, damage)
	block -= absorbed
	health = maxf(0.0, health - (damage - absorbed))
	if health <= 0.0 and not game_over:
		settle_game(true)

func finish_final_exam(passed: bool) -> void:
	game_over = true
	if passed:
		PlayerState.record_exam_pass(progress, progress_target)
		SaveManager.save_active_slot()
	get_tree().change_scene_to_file.call_deferred(SceneFade.FINAL_EXAM_ENDING_SCENE)

func finish_game() -> void:
	if resolving_turn or showing_turn_banner or card_effect_resolving:
		return
	settle_game(false)

func settle_game(automatic: bool) -> void:
	if game_over:
		return
	var passed := progress >= progress_target
	if not automatic and not passed:
		return
	if is_final_exam:
		finish_final_exam(passed)
		return
	game_over = true
	match_settled = true
	var reward_count := 0
	var allowance_bonus := 0
	if passed:
		reward_count = 2 if progress >= progress_target * 1.5 else 1
		allowance_bonus = PlayerState.record_exam_pass(progress, progress_target)
		UiSounds.play_victory()
	set_slots_selectable(false)
	if card_preview != null:
		card_preview.hide()
	update_values()
	if health <= 0.0 and health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	if not automatic:
		if end_button_tween and end_button_tween.is_running():
			end_button_tween.kill()
		end_button_tween = create_tween()
		end_button_tween.tween_property(end_button, "scale", Vector2(0.88, 0.88), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		end_button_tween.tween_property(end_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await end_button_tween.finished
	if SceneFade.curtain.visible:
		return
	end_button.hide()
	match_rewards = MATCH_REWARDS_SCENE.instantiate() as MatchRewards
	match_rewards.rewards_remaining = reward_count
	match_rewards.summary = "进度 %s / %d    ·    心态 %s    ·    回合 %d    ·    下一轮回满精力" % [
		format_value(progress), progress_target, format_value(health), turn,
	]
	if allowance_bonus > 0:
		match_rewards.summary += "\n今后每轮收入 +%d" % allowance_bonus
	match_rewards.continue_requested.connect(enter_next_round)
	ui.add_child(match_rewards)

func enter_next_round() -> void:
	if not is_instance_valid(match_rewards) or not match_rewards.reward_claimed:
		return
	start_next_round()

func start_next_round() -> void:
	if SceneFade.curtain.visible:
		return
	game_over = true
	SceneFade.advance_to_next_round()

func set_end_button_hover(hovered: bool) -> void:
	if game_over or not end_button.visible:
		return
	if end_button_tween and end_button_tween.is_running():
		end_button_tween.kill()
	end_button_tween = create_tween().set_parallel(true)
	end_button_tween.tween_property(end_button, "scale", Vector2(1.05, 1.05) if hovered else Vector2.ONE, 0.16)
	end_button_tween.tween_property(end_button, "self_modulate", Color(1.08, 1.04, 1.08) if hovered else Color.WHITE, 0.16)

func update_values() -> void:
	for card: Control in hand_holder.get_children():
		var card_id: int = card.get_meta("card_id")
		if PlayerState.card_base_id(source_card_id(card_id)) == CardCatalog.SHIRAKAWA_SNOW_CARD:
			set_battle_card_face(card.get_node("CardArt"), card_id)
	if not game_over and progress >= progress_target and not end_button.visible:
		end_button.modulate.a = 0.0
		end_button.scale = Vector2(0.85, 0.85)
		end_button.show()
		var fade := create_tween()
		fade.tween_property(end_button, "modulate:a", 1.0, 0.4)
		end_button_tween = create_tween()
		end_button_tween.tween_property(end_button, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif not game_over and progress < progress_target:
		end_button.hide()
	energy_value_label.text = str(energy)
	animate_health_display()
	progress_value_label.text = "%s / %d" % [format_value(progress), progress_target]
	if progress_fill != null:
		if progress_fill_tween and progress_fill_tween.is_running():
			progress_fill_tween.kill()
		var target_width := progress_track_width * clampf(float(progress) / progress_target, 0.0, 1.0)
		progress_fill_tween = create_tween()
		progress_fill_tween.tween_property(progress_fill, "size:x", target_width, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func animate_health_display() -> void:
	if health_display_target == health and block_display_target == block:
		return
	health_display_target = health
	block_display_target = block
	if health_display_tween and health_display_tween.is_running():
		health_display_tween.kill()
	health_display_tween = create_tween()
	# Show the shield being spent before any remaining damage reaches health.
	if not is_equal_approx(displayed_block, block):
		health_display_tween.tween_method(set_displayed_block, displayed_block, block, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not is_equal_approx(displayed_health, health):
		health_display_tween.tween_method(set_displayed_health, displayed_health, health, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_displayed_health(value: float) -> void:
	displayed_health = value
	refresh_health_display()

func set_displayed_block(value: float) -> void:
	displayed_block = value
	refresh_health_display()

func refresh_health_display() -> void:
	health_value_label.text = health_text()
	health_fill.size.x = health_track_width * clampf(displayed_health / max_health, 0.0, 1.0)
	block_fill.size.x = health_track_width * clampf(displayed_block / max_health, 0.0, 1.0)

func health_text() -> String:
	var current := str(int(displayed_health))
	if displayed_block >= 0.25:
		current += "+" + format_value(displayed_block)
	return "%s/%d" % [current, max_health]

func format_value(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return str(snappedf(value, 0.5))

func request_card_choice(cards: Array[int], from_hand: bool, prompt_text: String = "") -> int:
	deck_choice_overlay = Control.new()
	deck_choice_overlay.name = "HandDiscardOverlay" if from_hand else "DeckChoiceOverlay"
	deck_choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.z_index = 60
	ui.add_child(deck_choice_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.03, 0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.add_child(shade)

	var title := Label.new()
	title.text = "选择一张手牌弃置" if from_hand else "选择一张牌加入手牌"
	if not prompt_text.is_empty():
		title.text = prompt_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_choice_overlay.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 16.0
	title.offset_bottom = 60.0

	var options: Array[int] = []
	if from_hand:
		options = discardable_hand_indices()
	else:
		for card_id in cards:
			if not options.has(card_id):
				options.append(card_id)
		options.sort()
	var card_size := Vector2(185, 260)
	var grid_width := card_size.x * 3.0 + 36.0
	var scroll_width := grid_width + 40.0
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.add_child(scroll)
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.anchor_bottom = 1.0
	scroll.offset_left = -scroll_width / 2.0
	scroll.offset_right = scroll_width / 2.0
	scroll.offset_top = 64.0
	scroll.offset_bottom = -20.0

	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size.x = grid_width
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)

	for option in options:
		var card_id := cards[option] if from_hand else option
		var entry := Control.new()
		entry.custom_minimum_size = card_size
		entry.size = card_size
		entry.pivot_offset = card_size / 2.0
		entry.mouse_filter = Control.MOUSE_FILTER_PASS
		entry.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		entry.set_meta("choice", option)
		entry.gui_input.connect(on_card_choice_input.bind(option))
		grid.add_child(entry)

		var art := CardFace.new()
		set_battle_card_face(art, card_id)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.size = card_size
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(art)

		var count := 1 if from_hand else cards.count(card_id)
		if count > 1:
			var badge := Panel.new()
			badge.position = card_size - Vector2(46, 33)
			badge.size = Vector2(43, 30)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_style := StyleBoxFlat.new()
			badge_style.bg_color = Color(0.08, 0.07, 0.06, 0.88)
			badge_style.set_corner_radius_all(5)
			badge.add_theme_stylebox_override("panel", badge_style)
			entry.add_child(badge)
			var count_label := Label.new()
			count_label.text = "%dx" % count
			count_label.size = badge.size
			count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			count_label.add_theme_font_size_override("font_size", 20)
			count_label.add_theme_color_override("font_color", Color.WHITE)
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge.add_child(count_label)

	var choice: int = await card_choice_made
	deck_choice_overlay.hide()
	deck_choice_overlay.queue_free()
	deck_choice_overlay = null
	return choice

func on_card_choice_input(event: InputEvent, choice: int) -> void:
	if deck_choice_overlay != null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		card_choice_made.emit(choice)

func rearrange_remaining_hand() -> void:
	var remaining_cards := hand_holder.get_children()
	for card_index in remaining_cards.size():
		var card: Control = remaining_cards[card_index]
		card.set_meta("hand_index", card_index)
		card.position = get_fan_position(card_index, remaining_cards.size())
		card.rotation = get_fan_rotation(card_index, remaining_cards.size())
		card.scale = Vector2.ONE
		card.z_index = card_index

func create_card_preview(parent: Control) -> void:
	card_preview = Control.new()
	card_preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.z_index = 30
	card_preview.hide()
	parent.add_child(card_preview)

	var shade := ColorRect.new()
	shade.color = Color(0.07, 0.05, 0.03, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.add_child(shade)

	var detail_card := CardFace.new()
	detail_card.name = "DetailCard"
	detail_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_card.set_anchors_preset(Control.PRESET_CENTER)
	detail_card.position = Vector2(-135, -190)
	detail_card.size = Vector2(270, 380)
	detail_card.pivot_offset = detail_card.size * 0.5
	detail_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.add_child(detail_card)

func show_card_preview(card: Control) -> void:
	if game_over or card_effect_resolving or resolving_turn or selected_card != null or card.get_parent() != hand_holder:
		return
	card.z_index = 10
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var detail_card := card_preview.get_node("DetailCard") as CardFace
	if card_preview_tween and card_preview_tween.is_running():
		card_preview_tween.kill()
	set_battle_card_face(detail_card, int(card.get_meta("card_id")))
	detail_card.scale = Vector2.ONE * 0.8
	card_preview.show()
	card_preview_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_preview_tween.tween_property(detail_card, "scale", Vector2.ONE, 0.10)

func hide_card_preview(card: Control) -> void:
	card.z_index = int(card.get_meta("hand_index"))
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_preview.hide()
