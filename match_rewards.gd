extends ColorRect

signal continue_requested
signal deferred_requested
signal reward_skipped

enum Reward { NONE = -1, REMOVE, ADD, COPY, MONEY, AFFECTION, UPGRADE_POINTS, MAX_ENERGY, MAX_HEALTH, ENERGY_SUPPLY }

const CardCatalog := preload("res://card_catalog.gd")
const CardFace := preload("res://card_face.gd")
const SocialCharacters := preload("res://social_characters.gd")
const ButtonMotion := preload("res://phone_app_icon.gd")
const REWARD_ART := {
	Reward.REMOVE: preload("res://images/deck/1.png"),
	Reward.ADD: preload("res://images/deck/2.png"),
	Reward.COPY: preload("res://images/deck/3.png"),
	Reward.MONEY: preload("res://images/deck/4.png"),
	Reward.AFFECTION: preload("res://images/deck/5.png"),
	Reward.UPGRADE_POINTS: preload("res://images/deck/6.png"),
	Reward.MAX_ENERGY: preload("res://images/deck/7.png"),
	Reward.MAX_HEALTH: preload("res://images/deck/8.png"),
	Reward.ENERGY_SUPPLY: preload("res://images/deck/9.png"),
}
const CHARACTER_ART := {
	"ShiroLune": preload("res://images/character/ShiroLune_cutout.png"),
}
const OFFER_SIZE := 3
const CARD_ASPECT := 1.4
const MONEY_REWARD := 30
const AFFECTION_REWARD := 50
const UPGRADE_POINT_REWARD := 50
const MAX_ENERGY_REWARD := 2
const MAX_HEALTH_REWARD := 2
const ENERGY_SUPPLY_REWARD := 20

var summary := ""
var heading_text := "牌局结算"
var continue_text := "进入下一轮"
var fixed_offer: Array[int] = []
var level_reward_stat := -1
var requires_starter_deck := false
var result_only := false
var money_reward := MONEY_REWARD
var reward_claimed := false
var pending_reward := Reward.NONE
var reward_offer: Array[int] = []
var target_cards: Array[int] = []

@onready var summary_label: Label = %Summary
@onready var prompt: Label = %Prompt
@onready var scroll: ScrollContainer = %CardScroll
@onready var choices: GridContainer = %Choices
@onready var claimed_art: TextureRect = %ClaimedArt
@onready var next_button: Button = %NextRoundButton
@onready var skip_button: Button = %SkipButton


func _ready() -> void:
	%Heading.text = heading_text
	summary_label.text = summary
	summary_label.visible = not summary.is_empty()
	next_button.text = continue_text
	next_button.pressed.connect(func() -> void: continue_requested.emit())
	%LaterButton.pressed.connect(func() -> void: deferred_requested.emit())
	if result_only:
		reward_claimed = true
		prompt.hide()
		scroll.hide()
		claimed_art.get_parent().show()
		next_button.show()
		next_button.grab_focus()
		return
	skip_button.visible = level_reward_stat >= 0
	skip_button.pressed.connect(skip_level_reward)
	resized.connect(update_card_sizes)
	show_rewards()
	if requires_starter_deck:
		prompt.text = "组好初始卡组后，即可领取智商升级奖励"
		next_button.show()
		%LaterButton.show()


func show_rewards() -> void:
	var can_gain_affection := not affection_targets().is_empty()
	if fixed_offer.is_empty():
		var pool: Array[int] = []
		pool.assign(REWARD_ART.keys())
		if PlayerState.card_deck.size() <= 1:
			pool.erase(Reward.REMOVE)
		if not can_gain_affection:
			pool.erase(Reward.AFFECTION)
		pool.shuffle()
		reward_offer = pool.slice(0, OFFER_SIZE)
	else:
		reward_offer.assign(fixed_offer)
		if not can_gain_affection and reward_offer.size() > 1:
			reward_offer.erase(Reward.AFFECTION)
	var descriptions := {
		Reward.REMOVE: "删除卡组中的一张牌",
		Reward.ADD: "从三张牌中选一张加入卡组",
		Reward.COPY: "复制卡组中的一张牌",
		Reward.MONEY: "获得 %d 金钱" % money_reward,
		Reward.AFFECTION: "让一名角色获得至多 %d 点好感度" % PlayerState.social_affection_gain(AFFECTION_REWARD) if can_gain_affection else "角色好感度已满",
		Reward.UPGRADE_POINTS: "获得 %d 点升级点" % UPGRADE_POINT_REWARD,
		Reward.MAX_ENERGY: "精力上限 +%d" % MAX_ENERGY_REWARD,
		Reward.MAX_HEALTH: "心态上限 +%d" % MAX_HEALTH_REWARD,
		Reward.ENERGY_SUPPLY: "下一轮额外获得 %d 点精力" % ENERGY_SUPPLY_REWARD,
	}
	for reward in reward_offer:
		var can_remove := requires_starter_deck or reward != Reward.REMOVE or PlayerState.card_deck.size() > 1
		var caption: String = descriptions[reward] if can_remove else "卡组至少保留一张牌"
		var button := add_choice(REWARD_ART[reward], caption, choose_reward.bind(reward))
		if requires_starter_deck or not can_remove:
			button.disabled = true
			button.modulate.a = 0.45
	update_card_sizes()


func choose_reward(reward: int) -> void:
	if requires_starter_deck or pending_reward != Reward.NONE or not reward_offer.has(reward):
		return
	if reward == Reward.REMOVE and PlayerState.card_deck.size() <= 1:
		return
	pending_reward = reward
	match reward:
		Reward.REMOVE, Reward.ADD, Reward.COPY:
			show_card_targets(reward)
		Reward.MONEY:
			PlayerState.money += money_reward
			complete_reward("获得 %d 金钱" % money_reward)
		Reward.AFFECTION:
			var targets := affection_targets()
			if targets.is_empty():
				complete_reward("所有角色的好感度已满")
				return
			clear_choices()
			prompt.text = "选择一名角色增加好感度"
			for character: String in targets:
				var level := PlayerState.affection_progress(character).x
				var gain := PlayerState.affection_gain_for(character, AFFECTION_REWARD)
				var caption := "%s · %d 级 · 好感度 +%d" % [character, level, gain]
				add_choice(targets[character], caption, choose_character.bind(character))
			update_card_sizes()
		Reward.UPGRADE_POINTS:
			PlayerState.upgrade_points += UPGRADE_POINT_REWARD
			complete_reward("获得 %d 点升级点" % UPGRADE_POINT_REWARD)
		Reward.MAX_ENERGY:
			PlayerState.max_energy += MAX_ENERGY_REWARD
			PlayerState.current_energy += MAX_ENERGY_REWARD
			complete_reward("精力上限提升至 %d" % PlayerState.max_energy)
		Reward.MAX_HEALTH:
			PlayerState.max_health += MAX_HEALTH_REWARD
			complete_reward("心态上限提升至 %d" % PlayerState.max_health)
		Reward.ENERGY_SUPPLY:
			PlayerState.next_round_energy_bonus += ENERGY_SUPPLY_REWARD
			complete_reward("下一轮额外获得 %d 点精力" % ENERGY_SUPPLY_REWARD)


func show_card_targets(reward: int) -> void:
	clear_choices()
	var action := "加入卡组"
	if reward == Reward.ADD:
		var pool := CardCatalog.available_ids()
		pool.shuffle()
		target_cards = pool.slice(0, OFFER_SIZE)
	else:
		action = "删除" if reward == Reward.REMOVE else "复制"
		var unique_cards: Dictionary[int, int] = {}
		for card_id in PlayerState.card_deck:
			unique_cards[card_id] = unique_cards.get(card_id, 0) + 1
		target_cards.assign(unique_cards.keys())
		target_cards.sort()
	prompt.text = "选择一张牌%s" % action
	for card_id in target_cards:
		var caption := CardCatalog.card_name(PlayerState.card_base_id(card_id))
		if reward != Reward.ADD:
			caption += " ×%d" % PlayerState.card_deck.count(card_id)
		add_choice(null, caption, choose_target.bind(card_id), card_id)
	update_card_sizes()


func affection_targets() -> Dictionary:
	var targets := CHARACTER_ART.duplicate()
	for character in PlayerState.known_social_characters():
		targets[character] = SocialCharacters.avatar(character)
	for character: String in targets.keys():
		if PlayerState.affection_total(character) == PlayerState.MAX_AFFECTION:
			targets.erase(character)
	return targets


func choose_character(character: String) -> void:
	if reward_claimed or pending_reward != Reward.AFFECTION or not affection_targets().has(character):
		return
	var gain := PlayerState.add_character_affection(character, AFFECTION_REWARD)
	var level := PlayerState.affection_progress(character).x
	complete_reward("%s 好感度 +%d · 当前 %d 级" % [character, gain, level])


func choose_target(card_id: int) -> void:
	if reward_claimed or not target_cards.has(card_id):
		return
	var card_name := CardCatalog.card_name(PlayerState.card_base_id(card_id))
	match pending_reward:
		Reward.REMOVE:
			PlayerState.card_deck.erase(card_id)
			complete_reward("已从卡组删除「%s」" % card_name)
		Reward.ADD:
			PlayerState.card_deck.append(card_id)
			complete_reward("已将「%s」加入卡组" % card_name)
		Reward.COPY:
			PlayerState.card_deck.append(card_id)
			complete_reward("已复制「%s」" % card_name)


func settle_reward() -> void:
	reward_claimed = true
	if level_reward_stat >= 0:
		PlayerState.claimed_stat_levels[level_reward_stat] += 1
	PlayerState.changed.emit()


func skip_level_reward() -> void:
	if level_reward_stat < 0 or reward_claimed:
		return
	settle_reward()
	reward_skipped.emit()


func complete_reward(message: String) -> void:
	settle_reward()
	skip_button.hide()
	prompt.text = message
	clear_choices()
	scroll.hide()
	claimed_art.texture = REWARD_ART[pending_reward]
	claimed_art.get_parent().show()
	next_button.show()
	next_button.grab_focus()
	update_card_sizes()


func add_choice(texture: Texture2D, caption: String, action: Callable, card_id: int = -1) -> TextureButton:
	var entry := VBoxContainer.new()
	entry.alignment = BoxContainer.ALIGNMENT_CENTER
	entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	choices.add_child(entry)

	var button := TextureButton.new()
	button.set_script(ButtonMotion)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.tooltip_text = caption
	var art: TextureRect = CardFace.new() if card_id >= 0 else TextureRect.new()
	art.name = "Art"
	if card_id >= 0:
		(art as CardFace).set_card(card_id)
	else:
		art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(action)
	entry.add_child(button)

	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	entry.add_child(label)
	return button


func clear_choices() -> void:
	for entry in choices.get_children():
		choices.remove_child(entry)
		entry.queue_free()
	scroll.set_deferred("scroll_vertical", 0)


func update_card_sizes() -> void:
	var height_ratio := 0.40 if pending_reward in [Reward.REMOVE, Reward.COPY] else 0.54
	var width_limit := maxf(1.0, (size.x - 144.0) / OFFER_SIZE)
	var card_width := minf(255.0, minf(width_limit, size.y * height_ratio / CARD_ASPECT))
	var card_size := Vector2(card_width, card_width * CARD_ASPECT)
	for entry in choices.get_children():
		entry.get_child(0).custom_minimum_size = card_size
	claimed_art.custom_minimum_size = card_size * 0.82
