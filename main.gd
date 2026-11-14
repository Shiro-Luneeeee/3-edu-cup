extends Node2D

const STARTING_HAND_SIZE := 5
const STARTING_ENERGY := 3
const MAX_HEALTH := 20
const MAX_PROGRESS := 100
const MAX_HAND_SIZE := 9
const CARD_COSTS := [0, 0, 0, 1, 1, 1, 2, 2, 2, 3]
const CARD_SIZE := Vector2(142, 199)
const SLOT_POSITIONS := [Vector2(183, 334), Vector2(369, 334), Vector2(510, 334), Vector2(658, 334), Vector2(800, 334)]
const SLOT_SIZES := [Vector2(172, 180), Vector2(130, 180), Vector2(132, 180), Vector2(142, 180), Vector2(170, 180)]

var deck: Array = []
var hand: Array = []
var energy := STARTING_ENERGY
var health := MAX_HEALTH
var progress := 0
var block := 0
var turn := 1
var hand_holder: Control
var card_preview: Control
var slot_layer: Control
var selected_card: Control
var deck_choice_overlay: Control
var deck_choice_resolving := false
var pending_effect_draws: Array[int] = []
var health_fill: ColorRect
var progress_fill: Panel
var progress_fill_tween: Tween
const PROGRESS_FILL_WIDTH := 286.0
var hand_home_position := Vector2(-355, -235)
var hand_move_tween: Tween
var j_key_held := false
var last_j_trigger_msec := -1000

@onready var ui: Control = $HudLayer/UI
@onready var progress_value_label: Label = $HudLayer/UI/ProgressValueLabel
@onready var health_value_label: Label = $HudLayer/UI/HealthValueLabel
@onready var energy_value_label: Label = $HudLayer/UI/EnergyValueLabel
@onready var turn_value_label: Label = $HudLayer/UI/TurnValueLabel
@onready var block_value_label: Label = $HudLayer/UI/BlockValueLabel

var card_textures: Array[Texture2D] = [
	preload("res://images/card/0.png"), preload("res://images/card/1.png"),
	preload("res://images/card/2.png"), preload("res://images/card/3.png"),
	preload("res://images/card/4.png"), preload("res://images/card/5.png"),
	preload("res://images/card/6.png"), preload("res://images/card/7.png"),
	preload("res://images/card/8.png"), preload("res://images/card/9.png")
]
var health_texture := preload("res://images/金色月桂叶游戏生命条.png")
var progress_texture := preload("res://images/米色网格便签进度条界面.png")
var energy_texture := preload("res://images/复古纸张能量徽章图标.png")

func _ready() -> void:
	build_deck()
	draw_starting_hand()
	build_interface()
	await get_tree().process_frame
	hand_home_position = hand_holder.position
	animate_starting_hand()
	turn_value_label.text = "回合数：%d" % turn
	update_values()

func _unhandled_key_input(event: InputEvent) -> void:
	if deck_choice_overlay != null or deck_choice_resolving:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		end_turn()
		get_viewport().set_input_as_handled()
		return
	if not (event is InputEventKey) or event.keycode != KEY_J:
		return
	if not event.pressed:
		j_key_held = false
		return
	if event.echo or j_key_held:
		return
	var now_msec := Time.get_ticks_msec()
	if now_msec - last_j_trigger_msec < 900:
		return
	j_key_held = true
	last_j_trigger_msec = now_msec
	block_random_slot()
	get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if selected_card != null and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		cancel_selected_card()

func end_turn() -> void:
	turn += 1
	turn_value_label.text = "回合数：%d" % turn
	energy = STARTING_ENERGY
	update_values()
	reset_used_slots()
	if selected_card != null:
		selected_card = null
		set_slots_selectable(false)
		rearrange_remaining_hand()
		await return_hand_to_player()
	draw_card_at_turn_start()

func draw_card_at_turn_start() -> void:
	if deck.is_empty():
		return
	var drawn_card_id: int = deck.pop_back()
	if hand.size() >= MAX_HAND_SIZE:
		animate_discarded_draw(drawn_card_id)
		return
	add_card_to_hand(drawn_card_id, true)

func add_card_to_hand(card_id: int, animate_draw: bool = false) -> void:
	hand.append(card_id)
	var new_card := create_card(card_id)
	new_card.set_meta("hand_index", hand.size() - 1)
	new_card.set_meta("card_id", card_id)
	new_card.z_index = hand.size() - 1
	connect_card_interaction(new_card)
	new_card.position = Vector2(760, -330) if animate_draw else Vector2(284, 190)
	new_card.scale = Vector2(0.62, 0.62) if animate_draw else Vector2.ONE
	new_card.rotation = deg_to_rad(-18.0) if animate_draw else 0.0
	new_card.modulate.a = 0.75 if animate_draw else 0.0
	hand_holder.add_child(new_card)

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
	slot.get_node("BlockMark").show()
	if selected_card != null:
		if has_usable_slot():
			set_slots_selectable(true)
		else:
			cancel_selected_card()

func has_usable_slot() -> bool:
	for slot: Control in slot_layer.get_children():
		if can_use_slot(slot):
			return true
	return false

func is_slot_blocked(slot: Control) -> bool:
	return bool(slot.get_meta("blocked")) or int(slot.get_meta("blocked_until", 0)) >= turn

func can_use_slot(slot: Control) -> bool:
	if bool(slot.get_meta("used")):
		return false
	if selected_card != null and int(selected_card.get_meta("card_id")) == 8:
		return is_slot_blocked(slot)
	return not is_slot_blocked(slot)

func build_deck() -> void:
	deck.clear()
	for copy_index in 3:
		for card_id in 10:
			deck.append(card_id)
	deck.shuffle()

func draw_starting_hand() -> void:
	hand.clear()
	for card_index in STARTING_HAND_SIZE:
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
	meter.set_anchors_preset(Control.PRESET_TOP_LEFT)
	meter.position = Vector2(24, 4)
	meter.size = Vector2(420, 140)
	meter.z_index = 20
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(meter)
	progress_fill = Panel.new()
	progress_fill.position = Vector2(92, 65)
	progress_fill.size = Vector2(0, 24)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.96, 0.64, 0.25, 0.82)
	fill_style.set_corner_radius_all(8)
	progress_fill.add_theme_stylebox_override("panel", fill_style)
	meter.add_child(progress_fill)

	progress_value_label.text = "%d / %d" % [progress, MAX_PROGRESS]

func create_health_ui(parent: Control) -> void:
	var holder := Control.new()
	holder.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	holder.position = Vector2(24, -144)
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

	health_fill = ColorRect.new()
	health_fill.color = Color("b9363e")
	health_fill.position = Vector2(31, 43)
	health_fill.size = Vector2(272 * float(health) / MAX_HEALTH, 28)
	health_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(health_fill)

	health_value_label.text = "%d / %d" % [health, MAX_HEALTH]

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
	hand_holder.position = hand_home_position
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
		var hover_area: Control = card.get_node("HoverArea")
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

	var art := TextureRect.new()
	art.name = "CardArt"
	art.texture = card_textures[card_id]
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
		slot.position = SLOT_POSITIONS[slot_index]
		slot.size = SLOT_SIZES[slot_index]
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_meta("blocked", false)
		slot.set_meta("blocked_until", 0)
		slot.set_meta("reinforced_until", 0)
		slot.set_meta("used", false)
		slot.gui_input.connect(use_selected_card.bind(slot))
		slot_layer.add_child(slot)

		var glow := ColorRect.new()
		glow.name = "Glow"
		glow.size = Vector2(96, 112)
		glow.position = (slot.size - glow.size) / 2.0
		glow.color = Color.WHITE
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.material = make_center_glow_material()
		glow.hide()
		slot.add_child(glow)

		var block_mark := Label.new()
		block_mark.name = "BlockMark"
		block_mark.text = "❌"
		block_mark.add_theme_font_size_override("font_size", 58)
		block_mark.size = slot.size
		block_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		block_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		block_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		block_mark.hide()
		slot.add_child(block_mark)

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
	if deck_choice_resolving or selected_card != null or not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if energy < CARD_COSTS[int(card.get_meta("card_id"))]:
		return
	selected_card = card
	if not has_usable_slot():
		selected_card = null
		return
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
		if not is_slot_blocked(slot):
			slot.get_node("BlockMark").hide()

func return_hand_to_player() -> void:
	hand_move_tween = create_tween()
	hand_move_tween.tween_property(hand_holder, "position", hand_home_position, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await hand_move_tween.finished
	for hand_card in hand_holder.get_children():
		hand_card.get_node("HoverArea").mouse_filter = Control.MOUSE_FILTER_STOP

func move_hand_below_screen() -> void:
	if hand_move_tween and hand_move_tween.is_running():
		hand_move_tween.kill()
	# Move far enough for the entire card, including its rotation, to leave the viewport.
	var offscreen_y := get_viewport_rect().size.y + CARD_SIZE.y + 40.0
	hand_move_tween = create_tween()
	hand_move_tween.tween_property(hand_holder, "global_position:y", offscreen_y, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await hand_move_tween.finished

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

func use_selected_card(event: InputEvent, slot: Control) -> void:
	if selected_card == null or not (event is InputEventMouseButton):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	if slot.mouse_filter != Control.MOUSE_FILTER_STOP or not can_use_slot(slot):
		return

	var used_card := selected_card
	var card_id: int = used_card.get_meta("card_id")
	energy -= CARD_COSTS[card_id]
	hand.remove_at(int(used_card.get_meta("hand_index")))
	hand_holder.remove_child(used_card)
	used_card.queue_free()
	slot.set_meta("used", true)
	selected_card = null
	apply_card_effect(card_id, slot)
	set_slots_selectable(false)
	rearrange_remaining_hand()
	await return_hand_to_player()
	for drawn_card_id in pending_effect_draws:
		if hand.size() >= MAX_HAND_SIZE:
			animate_discarded_draw(drawn_card_id)
		else:
			add_card_to_hand(drawn_card_id, true)
	pending_effect_draws.clear()
	if card_id == 7:
		if deck.is_empty():
			end_turn()
		else:
			show_deck_choice()

func apply_card_effect(card_id: int, slot: Control) -> void:
	var multiplier := 2 if int(slot.get_meta("reinforced_until")) >= turn else 1
	match card_id:
		0:
			if not deck.is_empty():
				pending_effect_draws.append(deck.pop_back())
		1:
			progress += 3 * multiplier
		2:
			block += 3 * multiplier
		3:
			progress += 6 * multiplier
		4:
			health = mini(MAX_HEALTH, health + 4 * multiplier)
			block += 3 * multiplier
		5:
			slot.set_meta("reinforced_until", turn + 1)
		6:
			health = maxi(0, health - 4)
			progress += 24 * multiplier
		7:
			progress += 13 * multiplier
		8:
			slot.set_meta("blocked", false)
			slot.set_meta("blocked_until", 0)
			slot.get_node("BlockMark").hide()
			health = mini(MAX_HEALTH, health + 4 * multiplier)
			block += 3 * multiplier
		9:
			var targets: Array[Control] = []
			for target: Control in slot_layer.get_children():
				if target != slot and not is_slot_blocked(target):
					targets.append(target)
			if not targets.is_empty():
				var target: Control = targets.pick_random()
				target.set_meta("blocked_until", turn + 1)
				target.get_node("BlockMark").show()
			progress += 36 * multiplier
	update_values()

func update_values() -> void:
	energy_value_label.text = str(energy)
	health_value_label.text = "%d / %d" % [health, MAX_HEALTH]
	if health_fill != null:
		health_fill.size.x = 272.0 * float(health) / MAX_HEALTH
	progress_value_label.text = "%d / %d" % [progress, MAX_PROGRESS]
	if progress_fill != null:
		if progress_fill_tween and progress_fill_tween.is_running():
			progress_fill_tween.kill()
		var target_width := PROGRESS_FILL_WIDTH * clampf(float(progress) / MAX_PROGRESS, 0.0, 1.0)
		progress_fill_tween = create_tween()
		progress_fill_tween.tween_property(progress_fill, "size:x", target_width, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	block_value_label.text = "格挡：%d" % block

func show_deck_choice() -> void:
	if deck.is_empty():
		return
	deck_choice_overlay = Control.new()
	deck_choice_overlay.name = "DeckChoiceOverlay"
	deck_choice_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	deck_choice_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.z_index = 60
	ui.add_child(deck_choice_overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.03, 0.83)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.add_child(shade)

	var available_cards: Array[int] = []
	for card_id in 10:
		if deck.has(card_id):
			available_cards.append(card_id)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2((ui.size.x - 516.0) / 2.0, (ui.size.y - 550.0) / 2.0)
	scroll.size = Vector2(516, 550)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	deck_choice_overlay.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.custom_minimum_size.x = 486
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	scroll.add_child(grid)

	var card_size := Vector2(150, 210)
	for card_id in available_cards:
		var entry := Control.new()
		entry.custom_minimum_size = card_size
		entry.size = card_size
		entry.pivot_offset = card_size / 2.0
		entry.mouse_filter = Control.MOUSE_FILTER_PASS
		entry.gui_input.connect(on_deck_choice_input.bind(card_id))
		grid.add_child(entry)

		var art := TextureRect.new()
		art.texture = card_textures[card_id]
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.size = card_size
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(art)

		var count := deck.count(card_id)
		if count > 1:
			var badge := Panel.new()
			badge.position = Vector2(104, 177)
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

func on_deck_choice_input(event: InputEvent, card_id: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		choose_card_from_deck(card_id)

func choose_card_from_deck(card_id: int) -> void:
	if deck_choice_overlay == null or not deck.has(card_id):
		return
	deck_choice_resolving = true
	deck_choice_overlay.queue_free()
	deck_choice_overlay = null
	deck.erase(card_id)
	if hand.size() >= MAX_HAND_SIZE:
		animate_discarded_draw(card_id)
	else:
		add_card_to_hand(card_id, true)
		await get_tree().create_timer(0.6).timeout
	end_turn()
	await get_tree().create_timer(0.6).timeout
	rearrange_remaining_hand()
	deck_choice_resolving = false

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

	var detail_card := TextureRect.new()
	detail_card.name = "DetailCard"
	detail_card.texture = card_textures[0]
	detail_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_card.set_anchors_preset(Control.PRESET_CENTER)
	detail_card.position = Vector2(-135, -190)
	detail_card.size = Vector2(270, 380)
	detail_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_preview.add_child(detail_card)

func show_card_preview(card: Control) -> void:
	if selected_card != null or card.get_parent() != hand_holder:
		return
	card.z_index = 10
	var tween := create_tween().set_parallel(true)
	tween.tween_property(card, "scale", Vector2(1.25, 1.25), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_preview.show()
	card_preview.get_node("DetailCard").texture = card_textures[int(card.get_meta("card_id"))]

func hide_card_preview(card: Control) -> void:
	card.z_index = int(card.get_meta("hand_index"))
	var tween := create_tween()
	tween.tween_property(card, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	card_preview.hide()
