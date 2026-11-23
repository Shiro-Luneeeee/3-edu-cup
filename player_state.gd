extends Node

signal changed

enum Stat { INTELLIGENCE, EMOTIONAL_INTELLIGENCE, PHYSICAL_STRENGTH }

const CardCatalog := preload("res://card_catalog.gd")
const MapActivity := preload("res://map_activity_data.gd")
const RoundEvents := preload("res://round_event_catalog.gd")
const SocialCharacters := preload("res://social_characters.gd")
const ShopProducts := preload("res://shop_products.gd")
const STAT_NAMES := ["智商", "情商", "体魄"]
const STAT_CURVE_VERSION := 2
const LEGACY_STAT_FIRST_LEVEL_COST := 20
const STAT_FIRST_LEVEL_COST := 50
const STAT_LEVEL_COST_STEP := 10
const STAT_FIXED_COST_LEVEL := 10
const STAT_FIXED_LEVEL_COST := 200
const DEFAULT_MAX_ENERGY := 20
const DEFAULT_MAX_HEALTH := 20
const DEFAULT_MONEY := 500
const DEFAULT_PLAYER_NAME := "小满"
const ROUND_ALLOWANCE := 60
const MIN_STARTER_DECK_SIZE := 10
const MAX_STARTER_DECK_SIZE := 15
const FIRST_UPGRADED_CARD_ID := 1000
const AFFECTION_PER_LEVEL := 100
const MAX_AFFECTION_LEVEL := 10
const MAX_AFFECTION := AFFECTION_PER_LEVEL * MAX_AFFECTION_LEVEL

var max_energy := DEFAULT_MAX_ENERGY
var current_energy := DEFAULT_MAX_ENERGY
var round_energy_bonus := 0
var next_round_energy_bonus := 0
var max_health := DEFAULT_MAX_HEALTH
var player_name := DEFAULT_PLAYER_NAME
var park_meeting_seen := false
var yue_goldfish_seen := false
var yue_farewell_seen := false
var school_intro_seen := false
var round_number := 1
var intelligence := 0
var emotional_intelligence := 0
var physical_strength := 0
var upgrade_points := 0
var money := DEFAULT_MONEY
var owned_products: Array[String] = []
var daoxiang_act := 0
var daoxiang_last_age := 0
var daoxiang_reply := ""
var card_deck: Array[int] = []
var character_affection: Dictionary[String, int] = {}
var social_chat_history: Dictionary = {}
var social_efficiency_percent := 0
var claimed_stat_levels: Array[int] = [0, 0, 0]

var _initialized := false
var _starter_deck_completed := false
var _yue_story_cards_resolved := 0
var _last_event_round := 0
var _last_event_id := ""
var _pending_event_id := ""
var _activity_available_rounds: Dictionary[String, int] = {}
var _card_upgrades: Dictionary[int, Dictionary] = {}
var _next_upgraded_card_id := FIRST_UPGRADED_CARD_ID


func initialize(starting_intelligence: int, starting_emotional_intelligence: int, starting_physical_strength: int, starting_max_energy: int) -> void:
	if _initialized:
		return
	_initialized = true
	intelligence = starting_intelligence
	emotional_intelligence = starting_emotional_intelligence
	physical_strength = starting_physical_strength
	set_max_energy(starting_max_energy, true)


func reset() -> void:
	_initialized = false
	_starter_deck_completed = false
	_yue_story_cards_resolved = 0
	player_name = DEFAULT_PLAYER_NAME
	park_meeting_seen = false
	yue_goldfish_seen = false
	yue_farewell_seen = false
	school_intro_seen = false
	round_number = 1
	_last_event_round = 0
	_last_event_id = ""
	_pending_event_id = ""
	intelligence = 0
	emotional_intelligence = 0
	physical_strength = 0
	upgrade_points = 0
	round_energy_bonus = 0
	next_round_energy_bonus = 0
	max_health = DEFAULT_MAX_HEALTH
	money = DEFAULT_MONEY
	owned_products.clear()
	daoxiang_act = 0
	daoxiang_last_age = 0
	daoxiang_reply = ""
	card_deck.clear()
	_card_upgrades.clear()
	_next_upgraded_card_id = FIRST_UPGRADED_CARD_ID
	character_affection.clear()
	social_chat_history.clear()
	social_efficiency_percent = 0
	claimed_stat_levels.fill(0)
	_activity_available_rounds.clear()
	set_max_energy(DEFAULT_MAX_ENERGY, true)


func make_snapshot() -> Dictionary:
	return {
		"player_name": player_name,
		"max_energy": max_energy,
		"current_energy": current_energy,
		"round_energy_bonus": round_energy_bonus,
		"next_round_energy_bonus": next_round_energy_bonus,
		"max_health": max_health,
		"park_meeting_seen": park_meeting_seen,
		"yue_goldfish_seen": yue_goldfish_seen,
		"yue_farewell_seen": yue_farewell_seen,
		"school_intro_seen": school_intro_seen,
		"round_number": round_number,
		"last_event_round": _last_event_round,
		"last_event_id": _last_event_id,
		"intelligence": intelligence,
		"emotional_intelligence": emotional_intelligence,
		"physical_strength": physical_strength,
		"stat_curve_version": STAT_CURVE_VERSION,
		"upgrade_points": upgrade_points,
		"money": money,
		"owned_products": owned_products.duplicate(),
		"daoxiang_act": daoxiang_act,
		"daoxiang_last_age": daoxiang_last_age,
		"daoxiang_reply": daoxiang_reply,
		"card_deck": card_deck.duplicate(),
		"starter_deck_completed": has_starter_deck(),
		"yue_story_cards_resolved": _yue_story_cards_resolved,
		"card_upgrades": _card_upgrades.duplicate(true),
		"character_affection": character_affection.duplicate(),
		"social_chat_history": social_chat_history.duplicate(true),
		"social_efficiency_percent": social_efficiency_percent,
		"claimed_stat_levels": claimed_stat_levels.duplicate(),
		"activity_available_rounds": _activity_available_rounds.duplicate(),
	}


func restore_snapshot(data: Dictionary) -> void:
	max_energy = maxi(1, int(data.get("max_energy", DEFAULT_MAX_ENERGY)))
	var saved_bonus := maxi(0, int(data.get("round_energy_bonus", 0)))
	current_energy = clampi(int(data.get("current_energy", max_energy)), 0, max_energy + saved_bonus)
	round_energy_bonus = maxi(0, current_energy - max_energy)
	next_round_energy_bonus = maxi(0, int(data.get("next_round_energy_bonus", 0)))
	max_health = maxi(DEFAULT_MAX_HEALTH, int(data.get("max_health", DEFAULT_MAX_HEALTH)))
	var saved_name := str(data.get("player_name", "")).strip_edges()
	player_name = DEFAULT_PLAYER_NAME if saved_name.is_empty() else saved_name
	park_meeting_seen = bool(data.get("park_meeting_seen", false))
	yue_goldfish_seen = bool(data.get("yue_goldfish_seen", false))
	yue_farewell_seen = bool(data.get("yue_farewell_seen", false))
	school_intro_seen = bool(data.get("school_intro_seen", false))
	round_number = maxi(1, int(data.get("round_number", 1)))
	_last_event_round = clampi(int(data.get("last_event_round", round_number)), 0, round_number)
	_last_event_id = str(data.get("last_event_id", ""))
	_pending_event_id = ""
	_activity_available_rounds.clear()
	var saved_cooldowns: Variant = data.get("activity_available_rounds", {})
	if saved_cooldowns is Dictionary:
		for activity_id in saved_cooldowns:
			var available_round: Variant = saved_cooldowns[activity_id]
			if activity_id is String and (available_round is int or available_round is float) and int(available_round) > round_number:
				_activity_available_rounds[activity_id] = int(available_round)
	var uses_legacy_curve := data.has("claimed_stat_levels") and int(data.get("stat_curve_version", 1)) == 1
	intelligence = restore_stat_experience(int(data.get("intelligence", 0)), uses_legacy_curve)
	emotional_intelligence = restore_stat_experience(int(data.get("emotional_intelligence", 0)), uses_legacy_curve)
	physical_strength = restore_stat_experience(int(data.get("physical_strength", 0)), uses_legacy_curve)
	claimed_stat_levels.fill(0)
	var saved_levels: Variant = data.get("claimed_stat_levels", [])
	if saved_levels is Array:
		for stat in mini(saved_levels.size(), claimed_stat_levels.size()):
			if saved_levels[stat] is int or saved_levels[stat] is float:
				claimed_stat_levels[stat] = clampi(int(saved_levels[stat]), 0, stat_progress(stat).x)
	upgrade_points = maxi(0, int(data.get("upgrade_points", 0)))
	money = maxi(0, int(data.get("money", DEFAULT_MONEY)))
	social_efficiency_percent = maxi(0, int(data.get("social_efficiency_percent", 0)))
	owned_products.clear()
	for product_id in data.get("owned_products", []):
		if product_id is String and not owned_products.has(product_id):
			owned_products.append(product_id)
	daoxiang_act = clampi(int(data.get("daoxiang_act", 0)), 0, 3)
	daoxiang_last_age = maxi(0, int(data.get("daoxiang_last_age", 0)))
	daoxiang_reply = str(data.get("daoxiang_reply", ""))
	card_deck.clear()
	_starter_deck_completed = bool(data.get("starter_deck_completed", false))
	# A meeting completed in an older save has already passed its one-time offer.
	var legacy_resolved := maxi(int(park_meeting_seen), int(data.get("yue_story_cards_claimed", 0)))
	_yue_story_cards_resolved = maxi(0, int(data.get("yue_story_cards_resolved", legacy_resolved)))
	restore_card_upgrades(data.get("card_upgrades", {}))
	var saved_deck: Variant = data.get("card_deck", [])
	if saved_deck is Array:
		for saved_id: Variant in saved_deck:
			if not (saved_id is int or saved_id is float):
				continue
			var card_id := int(saved_id)
			if saved_id == card_id and CardCatalog.CARDS.has(card_base_id(card_id)):
				card_deck.append(card_id)
	character_affection.clear()
	var saved_affection: Variant = data.get("character_affection", {})
	if saved_affection is Dictionary:
		for character: Variant in saved_affection:
			var affection: Variant = saved_affection[character]
			if character is String and (affection is int or affection is float):
				character_affection[character] = clampi(int(affection), 0, MAX_AFFECTION)
	social_chat_history.clear()
	var saved_chats: Variant = data.get("social_chat_history", {})
	if saved_chats is Dictionary:
		for character in SocialCharacters.known_characters(park_meeting_seen):
			var records: Variant = saved_chats.get(character, [])
			if records is Array:
				var clean: Array[Dictionary] = []
				for record in records.slice(-20):
					if record is Dictionary and str(record.get("role", "")) in ["user", "assistant"]:
						var content := str(record.get("content", "")).left(500)
						if not content.is_empty():
							clean.append({"role": record["role"], "content": content})
				social_chat_history[character] = clean
	_initialized = true
	changed.emit()


func advance_round() -> void:
	round_number += 1
	for activity_id in _activity_available_rounds.keys():
		if _activity_available_rounds[activity_id] <= round_number:
			_activity_available_rounds.erase(activity_id)
	var product_effects := ShopProducts.recurring_effects(owned_products)
	money += ROUND_ALLOWANCE + int(product_effects.get("money", 0))
	intelligence += StudyProgress.get_level(StudyProgress.Subject.MATH) + int(product_effects.get("intelligence", 0))
	emotional_intelligence += StudyProgress.get_level(StudyProgress.Subject.CHINESE) + int(product_effects.get("emotional_intelligence", 0))
	physical_strength += int(product_effects.get("physical_strength", 0))
	upgrade_points += StudyProgress.get_level(StudyProgress.Subject.ENGLISH) + int(product_effects.get("upgrade_points", 0))
	round_energy_bonus = 0
	set_energy(max_energy)


func get_age_years() -> int:
	# Share the calendar used by the bedroom, seasonal events and social stories.
	return preload("res://round_calendar.gd").age(round_number)


func available_daoxiang_act() -> int:
	var age := get_age_years()
	match daoxiang_act:
		0: return 1 if age >= 6 and age <= 10 else 0
		1: return 2 if age >= 15 else 0
		2: return 3 if age >= 16 and age > daoxiang_last_age else 0
		_: return 0


func complete_daoxiang_act(act: int) -> void:
	if act != available_daoxiang_act():
		return
	daoxiang_act = act
	daoxiang_last_age = get_age_years()
	changed.emit()
func apply_next_round_energy_bonus() -> void:
	if next_round_energy_bonus <= 0:
		return
	var amount := next_round_energy_bonus
	next_round_energy_bonus = 0
	set_energy(current_energy + amount, true)


func roll_round_event() -> String:
	if _last_event_round == round_number:
		return _pending_event_id
	_last_event_round = round_number
	_pending_event_id = RoundEvents.draw_event(round_number, _last_event_id)
	if not _pending_event_id.is_empty():
		_last_event_id = _pending_event_id
	return _pending_event_id


func round_event_shortage(effects: Dictionary) -> String:
	var costs := PackedStringArray()
	if money + int(effects.get("money", 0)) < 0:
		costs.append("金钱")
	if current_energy + int(effects.get("current_energy", 0)) < 0:
		costs.append("精力")
	return "" if costs.is_empty() else "、".join(costs) + "不足"


func try_resolve_round_event(option_index: int) -> bool:
	if _last_event_round != round_number or _pending_event_id.is_empty():
		return false
	var options: Array = RoundEvents.EVENTS[_pending_event_id]["options"]
	if option_index < 0 or option_index >= options.size():
		return false
	var effects: Dictionary = options[option_index]["effects"]
	if not round_event_shortage(effects).is_empty():
		return false
	_pending_event_id = ""
	money += int(effects.get("money", 0))
	intelligence += int(effects.get("intelligence", 0))
	emotional_intelligence += int(effects.get("emotional_intelligence", 0))
	physical_strength += int(effects.get("physical_strength", 0))
	upgrade_points += int(effects.get("upgrade_points", 0))
	set_energy(current_energy + int(effects.get("current_energy", 0)), true)
	return true


func stat_experience_required(level: int) -> int:
	return STAT_FIRST_LEVEL_COST + level * STAT_LEVEL_COST_STEP if level < STAT_FIXED_COST_LEVEL else STAT_FIXED_LEVEL_COST


func stat_progress(stat: int) -> Vector2i:
	var experience: int = [intelligence, emotional_intelligence, physical_strength][stat]
	return progress_from_experience(experience, STAT_FIRST_LEVEL_COST)


@warning_ignore("integer_division")
func progress_from_experience(experience: int, first_level_cost: int) -> Vector2i:
	var level := 0
	var cost := first_level_cost
	while level < STAT_FIXED_COST_LEVEL and experience >= cost:
		experience -= cost
		level += 1
		cost += STAT_LEVEL_COST_STEP
	if level == STAT_FIXED_COST_LEVEL:
		level += experience / STAT_FIXED_LEVEL_COST
		experience %= STAT_FIXED_LEVEL_COST
	return Vector2i(level, experience)


func restore_stat_experience(saved_experience: int, uses_legacy_curve: bool) -> int:
	var experience := maxi(0, saved_experience)
	if uses_legacy_curve:
		var reached_level := progress_from_experience(experience, LEGACY_STAT_FIRST_LEVEL_COST).x
		# Keep levels and spare experience earned under the previous thresholds.
		experience += mini(reached_level, STAT_FIXED_COST_LEVEL) * (STAT_FIRST_LEVEL_COST - LEGACY_STAT_FIRST_LEVEL_COST)
	return experience


func next_stat_reward(skip_intelligence: bool = false) -> int:
	for stat: int in Stat.values():
		if stat == Stat.INTELLIGENCE and skip_intelligence:
			continue
		if claimed_stat_levels[stat] < stat_progress(stat).x:
			return stat
	return -1


func has_starter_deck() -> bool:
	return not card_deck.is_empty() and (_starter_deck_completed or card_deck.any(func(card_id: int) -> bool:
		return card_base_id(card_id) < CardCatalog.YUE_FIRST_CARD
	))


func finish_starter_deck(drafted_cards: Array[int]) -> void:
	card_deck.append_array(drafted_cards)
	_starter_deck_completed = true


func card_base_id(card_id: int) -> int:
	return int(_card_upgrades[card_id]["base_id"]) if _card_upgrades.has(card_id) else card_id


func card_numbers(card_id: int) -> Dictionary:
	if _card_upgrades.has(card_id):
		return _card_upgrades[card_id]["numbers"].duplicate()
	return CardCatalog.numbers(card_id)


func card_cost(card_id: int) -> int:
	return CardCatalog.cost(card_base_id(card_id))


func try_upgrade_card(deck_index: int, operation: int, field: String = "") -> bool:
	if deck_index < 0 or deck_index >= card_deck.size() or upgrade_points < CardCatalog.UPGRADE_COST:
		return false
	var card_id := card_deck[deck_index]
	var base_id := card_base_id(card_id)
	var original := card_numbers(card_id)
	var upgraded := CardCatalog.upgraded_numbers(base_id, original, operation, field)
	if upgraded == original:
		return false
	var new_id := _next_upgraded_card_id
	_next_upgraded_card_id += 1
	_card_upgrades[new_id] = {"base_id": base_id, "numbers": upgraded}
	card_deck[deck_index] = new_id
	if not card_deck.has(card_id):
		_card_upgrades.erase(card_id)
	upgrade_points -= CardCatalog.UPGRADE_COST
	changed.emit()
	return true


func restore_card_upgrades(saved_upgrades: Variant) -> void:
	_card_upgrades.clear()
	_next_upgraded_card_id = FIRST_UPGRADED_CARD_ID
	if not saved_upgrades is Dictionary:
		return
	for saved_id in saved_upgrades:
		if not str(saved_id).is_valid_int():
			continue
		var card_id := int(saved_id)
		var record: Variant = saved_upgrades[saved_id]
		if card_id < FIRST_UPGRADED_CARD_ID or not record is Dictionary:
			continue
		var base_id := int(record.get("base_id", -1))
		var saved_numbers: Variant = record.get("numbers", {})
		if not CardCatalog.CARDS.has(base_id) or not saved_numbers is Dictionary:
			continue
		var numbers := CardCatalog.numbers(base_id)
		for field: String in CardCatalog.number_regions(base_id):
			var value: Variant = saved_numbers.get(field)
			if value is int or value is float:
				numbers[field] = maxi(CardCatalog.minimum_number(field), int(value))
		_card_upgrades[card_id] = {"base_id": base_id, "numbers": numbers}
		_next_upgraded_card_id = maxi(_next_upgraded_card_id, card_id + 1)


func try_buy_product(product_id: String, price: int, repeatable: bool, effects: Dictionary) -> bool:
	if price < 0 or money < price or (not repeatable and owned_products.has(product_id)):
		return false
	money -= price
	if not repeatable:
		owned_products.append(product_id)
	intelligence = maxi(0, intelligence + int(effects.get("intelligence", 0)))
	emotional_intelligence = maxi(0, emotional_intelligence + int(effects.get("emotional_intelligence", 0)))
	physical_strength = maxi(0, physical_strength + int(effects.get("physical_strength", 0)))
	upgrade_points = maxi(0, upgrade_points + int(effects.get("upgrade_points", 0)))
	social_efficiency_percent = maxi(0, social_efficiency_percent + int(effects.get("social_efficiency_percent", 0)))
	max_energy = maxi(1, max_energy + int(effects.get("max_energy", 0)))
	max_health = maxi(DEFAULT_MAX_HEALTH, max_health + int(effects.get("max_health", 0)))
	var energy_change := int(effects.get("current_energy", 0))
	set_energy(current_energy + energy_change, energy_change > 0)
	return true


func social_affection_gain(base_amount: int) -> int:
	return roundi(base_amount * (1.0 + social_efficiency_percent / 100.0))


func affection_total(character: String) -> int:
	return clampi(character_affection.get(character, 0), 0, MAX_AFFECTION)


@warning_ignore("integer_division")
func affection_progress(character: String) -> Vector2i:
	var total := affection_total(character)
	var level := total / AFFECTION_PER_LEVEL
	var progress := AFFECTION_PER_LEVEL if level == MAX_AFFECTION_LEVEL else total % AFFECTION_PER_LEVEL
	return Vector2i(level, progress)


func affection_gain_for(character: String, base_amount: int) -> int:
	return clampi(social_affection_gain(base_amount), 0, MAX_AFFECTION - affection_total(character))


func add_character_affection(character: String, base_amount: int) -> int:
	var gain := affection_gain_for(character, base_amount)
	if gain > 0:
		character_affection[character] = affection_total(character) + gain
	return gain


func yue_park_chapter() -> SocialCharacters.YueChapter:
	# Saves from before the second card was added can still make its one-time choice.
	if yue_goldfish_seen and yue_story_card_offer(SocialCharacters.YueChapter.GOLDFISH) >= 0:
		return SocialCharacters.YueChapter.GOLDFISH
	return SocialCharacters.yue_park_chapter(round_number, park_meeting_seen, yue_goldfish_seen, yue_farewell_seen, affection_progress(SocialCharacters.YUE).x)


func finish_yue_park_story(chapter: SocialCharacters.YueChapter, add_story_card: bool) -> void:
	if chapter == SocialCharacters.YueChapter.NONE or chapter != yue_park_chapter():
		return
	match chapter:
		SocialCharacters.YueChapter.FIRST_MEETING: park_meeting_seen = true
		SocialCharacters.YueChapter.GOLDFISH: yue_goldfish_seen = true
		SocialCharacters.YueChapter.FAREWELL: yue_farewell_seen = true
	resolve_yue_story_card(chapter, add_story_card)
	changed.emit()


func yue_story_card_offer(chapter_index: int) -> int:
	return CardCatalog.yue_story_card(chapter_index) if chapter_index == _yue_story_cards_resolved else -1


func resolve_yue_story_card(chapter_index: int, add_to_deck: bool) -> void:
	var card_id := yue_story_card_offer(chapter_index)
	if card_id < 0:
		return
	_yue_story_cards_resolved += 1
	if add_to_deck and not card_deck.any(func(existing_id: int) -> bool: return card_base_id(existing_id) == card_id):
		card_deck.append(card_id)


func try_socialize(character: String) -> bool:
	if character not in SocialCharacters.known_characters(park_meeting_seen) or current_energy < SocialCharacters.CHAT_ENERGY_COST:
		return false
	if add_character_affection(character, SocialCharacters.CHAT_AFFECTION_GAIN) == 0:
		return false
	set_energy(current_energy - SocialCharacters.CHAT_ENERGY_COST)
	return true


func owns_game(game_id: String) -> bool:
	return owned_products.has("game:" + game_id)


func try_buy_game(game_id: String, price: int) -> bool:
	if game_id.is_empty() or price <= 0:
		return false
	return try_buy_product("game:" + game_id, price, false, {})


func try_start_game(game_id: String, energy_cost: int) -> bool:
	if not owns_game(game_id) or energy_cost < 0 or current_energy < energy_cost:
		return false
	set_energy(current_energy - energy_cost)
	return true


func reward_game(stat: String, amount: int) -> void:
	if amount <= 0:
		return
	match stat:
		"intelligence": intelligence += amount
		"emotional_intelligence": emotional_intelligence += amount
		"physical_strength": physical_strength += amount
		_:
			push_error("Unknown game reward: %s" % stat)
			return
	changed.emit()


func set_energy(value: int, allow_overflow: bool = false) -> void:
	current_energy = maxi(0, value) if allow_overflow else clampi(value, 0, max_energy + round_energy_bonus)
	round_energy_bonus = maxi(0, current_energy - max_energy)
	changed.emit()


func set_max_energy(value: int, refill: bool = false) -> void:
	max_energy = maxi(1, value)
	set_energy(max_energy + round_energy_bonus if refill else current_energy)


func energy_text() -> String:
	var base := "%d/%d" % [mini(current_energy, max_energy), max_energy]
	return "%s +%d" % [base, round_energy_bonus] if round_energy_bonus > 0 else base


func try_apply_action(energy_cost: int, intelligence_gain: int, emotional_gain: int, upgrade_point_gain: int) -> bool:
	if energy_cost < 0 or current_energy < energy_cost:
		return false
	intelligence += intelligence_gain
	emotional_intelligence += emotional_gain
	upgrade_points += upgrade_point_gain
	set_energy(current_energy - energy_cost)
	return true


func activity_available_round(activity_id: String) -> int:
	return _activity_available_rounds.get(activity_id, round_number)


func can_apply_map_activity(activity: MapActivity) -> bool:
	return (
		activity_available_round(activity.cooldown_id) <= round_number
		and current_energy + activity.energy_change >= 0
		and money + activity.money_change >= 0
		and activity.max_health_gain >= 0
	)


func try_apply_map_activity(activity: MapActivity) -> bool:
	if not can_apply_map_activity(activity):
		return false
	if activity.cooldown_rounds > 0 and not activity.cooldown_id.is_empty():
		_activity_available_rounds[activity.cooldown_id] = round_number + activity.cooldown_rounds
	money += activity.money_change
	physical_strength += activity.physical_gain
	max_health += activity.max_health_gain
	set_energy(current_energy + activity.energy_change, activity.energy_change > 0)
	return true
