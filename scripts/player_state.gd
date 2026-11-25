extends Node

signal changed

enum Stat { INTELLIGENCE, EMOTIONAL_INTELLIGENCE, PHYSICAL_STRENGTH }

const CardCatalog := preload("res://scripts/card_catalog.gd")
const MapActivity := preload("res://scripts/map_activity_data.gd")
const RoundEvents := preload("res://scripts/round_event_catalog.gd")
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const SocialCharacters := preload("res://scripts/social_characters.gd")
const ShopProducts := preload("res://scripts/shop_products.gd")
const GameAesthetic := preload("res://scripts/game_aesthetic.gd")
const STAT_NAMES := ["智商", "情商", "体魄"]
const STAT_CURVE_VERSION := 2
const LEGACY_STAT_FIRST_LEVEL_COST := 20
const STAT_FIRST_LEVEL_COST := 50
const STAT_LEVEL_COST_STEP := 10
const STAT_FIXED_COST_LEVEL := 10
const STAT_FIXED_LEVEL_COST := 200
const DEFAULT_MAX_ENERGY := 20
const DEFAULT_MAX_HEALTH := 20
const DEFAULT_MONEY := 0
const DEFAULT_PLAYER_NAME := "樱白 满"
const ROUND_ALLOWANCE := 10
const MIN_STARTER_DECK_SIZE := 10
const MAX_STARTER_DECK_SIZE := 15
const FIRST_UPGRADED_CARD_ID := 1000
const AFFECTION_PER_LEVEL := 100
const MAX_AFFECTION_LEVEL := 10
const MAX_AFFECTION := AFFECTION_PER_LEVEL * MAX_AFFECTION_LEVEL
const FREE_CHAT_AFFECTION_GAIN := 2
const FREE_CHAT_AFFECTION_ROUND_CAP := 10

var max_energy := DEFAULT_MAX_ENERGY
var current_energy := DEFAULT_MAX_ENERGY
var round_energy_bonus := 0
var next_round_energy_bonus := 0
var max_health := DEFAULT_MAX_HEALTH
var player_name := DEFAULT_PLAYER_NAME
var bedroom_tutorial_pending := false
var bedroom_tutorial_seen := false
var battle_tutorial_seen := false
var park_meeting_seen := false
var yue_goldfish_seen := false
var yue_farewell_seen := false
var yue_final_promise_seen := false
var romantic_partner := ""
var school_intro_seen := false
var middle_school_intro_seen := false
var high_school_intro_seen := false
var fushimi_pen_seen := false
var fushimi_pen_card_resolved := false
var fushimi_tutoring_seen := false
var fushimi_bookshop_seen := false
var fushimi_confession_seen := false
var fushimi_final_promise_seen := false
var shirakawa_first_story_seen := false
var shirakawa_second_story_seen := false
var shirakawa_third_story_seen := false
var shirakawa_confession_seen := false
var shirakawa_snow_seen := false
var round_number := 1
var passed_exams := 0
var exam_allowance_bonus := 0
var final_exam_started := false
var final_exam_passed := false
var intelligence := 0
var emotional_intelligence := 0
var physical_strength := 0
var upgrade_points := 0
var money := DEFAULT_MONEY
var owned_products: Array[String] = []
var game_aesthetic_points := 0
var game_play_counts: Dictionary[String, int] = {}
var game_aesthetic_rewards_claimed := 0
var daoxiang_act := 0
var daoxiang_last_age := 0
var daoxiang_reply := ""
var card_deck: Array[int] = []
var character_affection: Dictionary[String, int] = {}
var social_chat_history: Dictionary = {}
var free_chat_affection_this_round: Dictionary[String, int] = {}
var social_affection_notice_seen := false
var social_efficiency_percent := 0
var claimed_stat_levels: Array[int] = [0, 0, 0]

var _initialized := false
var _starter_deck_completed := false
var _yue_story_cards_resolved := 0
var _last_event_round := 0
var _last_event_id := ""
var _pending_event_id := ""
var _activity_available_rounds: Dictionary[String, int] = {}
var _mental_stat_bonus_remainder := Vector2i.ZERO
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
	bedroom_tutorial_pending = false
	bedroom_tutorial_seen = false
	battle_tutorial_seen = false
	park_meeting_seen = false
	yue_goldfish_seen = false
	yue_farewell_seen = false
	yue_final_promise_seen = false
	romantic_partner = ""
	school_intro_seen = false
	middle_school_intro_seen = false
	high_school_intro_seen = false
	fushimi_pen_seen = false
	fushimi_pen_card_resolved = false
	fushimi_tutoring_seen = false
	fushimi_bookshop_seen = false
	fushimi_confession_seen = false
	fushimi_final_promise_seen = false
	shirakawa_first_story_seen = false
	shirakawa_second_story_seen = false
	shirakawa_third_story_seen = false
	shirakawa_confession_seen = false
	shirakawa_snow_seen = false
	round_number = 1
	passed_exams = 0
	exam_allowance_bonus = 0
	final_exam_started = false
	final_exam_passed = false
	_last_event_round = 0
	_last_event_id = ""
	_pending_event_id = ""
	intelligence = 0
	emotional_intelligence = 0
	_mental_stat_bonus_remainder = Vector2i.ZERO
	physical_strength = 0
	upgrade_points = 0
	round_energy_bonus = 0
	next_round_energy_bonus = 0
	max_health = DEFAULT_MAX_HEALTH
	money = DEFAULT_MONEY
	owned_products.clear()
	game_aesthetic_points = 0
	game_play_counts.clear()
	game_aesthetic_rewards_claimed = 0
	daoxiang_act = 0
	daoxiang_last_age = 0
	daoxiang_reply = ""
	card_deck.clear()
	_card_upgrades.clear()
	_next_upgraded_card_id = FIRST_UPGRADED_CARD_ID
	character_affection.clear()
	social_chat_history.clear()
	free_chat_affection_this_round.clear()
	social_affection_notice_seen = false
	social_efficiency_percent = 0
	claimed_stat_levels.fill(0)
	_activity_available_rounds.clear()
	set_max_energy(DEFAULT_MAX_ENERGY, true)


func make_snapshot() -> Dictionary:
	return {
		"player_name": player_name,
		"bedroom_tutorial_seen": bedroom_tutorial_seen,
		"battle_tutorial_seen": battle_tutorial_seen,
		"max_energy": max_energy,
		"current_energy": current_energy,
		"round_energy_bonus": round_energy_bonus,
		"next_round_energy_bonus": next_round_energy_bonus,
		"max_health": max_health,
		"park_meeting_seen": park_meeting_seen,
		"yue_goldfish_seen": yue_goldfish_seen,
		"yue_farewell_seen": yue_farewell_seen,
		"yue_final_promise_seen": yue_final_promise_seen,
		"romantic_partner": romantic_partner,
		"school_intro_seen": school_intro_seen,
		"middle_school_intro_seen": middle_school_intro_seen,
		"high_school_intro_seen": high_school_intro_seen,
		"fushimi_pen_seen": fushimi_pen_seen,
		"fushimi_pen_card_resolved": fushimi_pen_card_resolved,
		"fushimi_tutoring_seen": fushimi_tutoring_seen,
		"fushimi_bookshop_seen": fushimi_bookshop_seen,
		"fushimi_confession_seen": fushimi_confession_seen,
		"fushimi_final_promise_seen": fushimi_final_promise_seen,
		"shirakawa_first_story_seen": shirakawa_first_story_seen,
		"shirakawa_second_story_seen": shirakawa_second_story_seen,
		"shirakawa_third_story_seen": shirakawa_third_story_seen,
		"shirakawa_confession_seen": shirakawa_confession_seen,
		"shirakawa_snow_seen": shirakawa_snow_seen,
		"round_number": round_number,
		"passed_exams": passed_exams,
		"exam_allowance_bonus": exam_allowance_bonus,
		"final_exam_started": final_exam_started,
		"final_exam_passed": final_exam_passed,
		"last_event_round": _last_event_round,
		"last_event_id": _last_event_id,
		"intelligence": intelligence,
		"emotional_intelligence": emotional_intelligence,
		"intelligence_bonus_remainder": _mental_stat_bonus_remainder.x,
		"emotional_intelligence_bonus_remainder": _mental_stat_bonus_remainder.y,
		"physical_strength": physical_strength,
		"stat_curve_version": STAT_CURVE_VERSION,
		"upgrade_points": upgrade_points,
		"money": money,
		"owned_products": owned_products.duplicate(),
		"game_aesthetic_points": game_aesthetic_points,
		"game_play_counts": game_play_counts.duplicate(),
		"game_aesthetic_rewards_claimed": game_aesthetic_rewards_claimed,
		"daoxiang_act": daoxiang_act,
		"daoxiang_last_age": daoxiang_last_age,
		"daoxiang_reply": daoxiang_reply,
		"card_deck": card_deck.duplicate(),
		"starter_deck_completed": has_starter_deck(),
		"yue_story_cards_resolved": _yue_story_cards_resolved,
		"card_upgrades": _card_upgrades.duplicate(true),
		"character_affection": character_affection.duplicate(),
		"social_chat_history": social_chat_history.duplicate(true),
		"free_chat_affection_this_round": free_chat_affection_this_round.duplicate(),
		"social_affection_notice_seen": social_affection_notice_seen,
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
	bedroom_tutorial_pending = false
	bedroom_tutorial_seen = bool(data.get("bedroom_tutorial_seen", true))
	park_meeting_seen = bool(data.get("park_meeting_seen", false))
	yue_goldfish_seen = bool(data.get("yue_goldfish_seen", false))
	yue_farewell_seen = bool(data.get("yue_farewell_seen", false))
	yue_final_promise_seen = bool(data.get("yue_final_promise_seen", false))
	var saved_partner: Variant = data.get("romantic_partner", "")
	romantic_partner = saved_partner if saved_partner is String else ""
	school_intro_seen = bool(data.get("school_intro_seen", false))
	middle_school_intro_seen = bool(data.get("middle_school_intro_seen", false))
	high_school_intro_seen = bool(data.get("high_school_intro_seen", false))
	fushimi_pen_seen = bool(data.get("fushimi_pen_seen", false))
	fushimi_pen_card_resolved = bool(data.get("fushimi_pen_card_resolved", fushimi_pen_seen))
	fushimi_tutoring_seen = bool(data.get("fushimi_tutoring_seen", false))
	fushimi_bookshop_seen = bool(data.get("fushimi_bookshop_seen", false))
	fushimi_confession_seen = bool(data.get("fushimi_confession_seen", false))
	fushimi_final_promise_seen = bool(data.get("fushimi_final_promise_seen", false))
	shirakawa_first_story_seen = bool(data.get("shirakawa_first_story_seen", false))
	shirakawa_second_story_seen = bool(data.get("shirakawa_second_story_seen", false))
	shirakawa_third_story_seen = bool(data.get("shirakawa_third_story_seen", false))
	shirakawa_confession_seen = bool(data.get("shirakawa_confession_seen", false))
	shirakawa_snow_seen = bool(data.get("shirakawa_snow_seen", false))
	round_number = clampi(int(data.get("round_number", 1)), 1, RoundCalendar.FINAL_EXAM_ROUND)
	passed_exams = maxi(0, int(data.get("passed_exams", 0)))
	exam_allowance_bonus = maxi(0, int(data.get("exam_allowance_bonus", 0)))
	final_exam_passed = RoundCalendar.is_final_exam(round_number) and bool(data.get("final_exam_passed", false))
	final_exam_started = RoundCalendar.is_final_exam(round_number) and (final_exam_passed or bool(data.get("final_exam_started", false)))
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
	_mental_stat_bonus_remainder = Vector2i(
		clampi(int(data.get("intelligence_bonus_remainder", 0)), 0, 99),
		clampi(int(data.get("emotional_intelligence_bonus_remainder", 0)), 0, 99)
	)
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
	var legacy_aesthetic_claimed := bool(data.get("game_aesthetic_reward_claimed", false))
	game_aesthetic_rewards_claimed = maxi(0, int(data.get("game_aesthetic_rewards_claimed", int(legacy_aesthetic_claimed))))
	# The old one-time reward kept its spent points on the full meter.
	game_aesthetic_points = 0 if legacy_aesthetic_claimed and not data.has("game_aesthetic_rewards_claimed") else maxi(0, int(data.get("game_aesthetic_points", 0)))
	game_play_counts.clear()
	var saved_game_plays: Variant = data.get("game_play_counts", {})
	if saved_game_plays is Dictionary:
		for game_id in saved_game_plays:
			if game_id is String and GameAesthetic.contains_game(game_id):
				game_play_counts[game_id] = clampi(int(saved_game_plays[game_id]), 0, 100000)
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
	battle_tutorial_seen = bool(data.get("battle_tutorial_seen", _starter_deck_completed or has_starter_deck()))
	character_affection.clear()
	var saved_affection: Variant = data.get("character_affection", {})
	if saved_affection is Dictionary:
		for character: Variant in saved_affection:
			var affection: Variant = saved_affection[character]
			if character is String and (affection is int or affection is float):
				character_affection[character] = clampi(int(affection), 0, MAX_AFFECTION)
	free_chat_affection_this_round.clear()
	var saved_free_chat_affection: Variant = data.get("free_chat_affection_this_round", {})
	if saved_free_chat_affection is Dictionary:
		for character in known_social_characters():
			var earned: Variant = saved_free_chat_affection.get(character, 0)
			if earned is int or earned is float:
				free_chat_affection_this_round[character] = clampi(int(earned), 0, FREE_CHAT_AFFECTION_ROUND_CAP)
	social_affection_notice_seen = bool(data.get("social_affection_notice_seen", false))
	social_chat_history.clear()
	var saved_chats: Variant = data.get("social_chat_history", {})
	if saved_chats is Dictionary:
		for character in known_social_characters():
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


func record_exam_pass(progress: float, target: int) -> int:
	if final_exam_passed or target <= 0 or progress < target:
		return 0
	var bonus := 0
	if progress * 100.0 > target * 150:
		bonus = 2
	elif progress * 100.0 > target * 120:
		bonus = 1
	exam_allowance_bonus += bonus
	passed_exams += 1
	if RoundCalendar.is_final_exam(round_number):
		final_exam_started = true
		final_exam_passed = true
	changed.emit()
	return bonus


func advance_round() -> void:
	round_number += 1
	free_chat_affection_this_round.clear()
	for activity_id in _activity_available_rounds.keys():
		if _activity_available_rounds[activity_id] <= round_number:
			_activity_available_rounds.erase(activity_id)
	var product_effects := ShopProducts.recurring_effects(owned_products)
	money += ROUND_ALLOWANCE + exam_allowance_bonus + int(product_effects.get("money", 0))
	add_mental_stat_experience(
		StudyProgress.get_level(StudyProgress.Subject.MATH) + int(product_effects.get("intelligence", 0)),
		StudyProgress.get_level(StudyProgress.Subject.CHINESE) + int(product_effects.get("emotional_intelligence", 0))
	)
	physical_strength += int(product_effects.get("physical_strength", 0))
	upgrade_points += StudyProgress.get_level(StudyProgress.Subject.ENGLISH) + int(product_effects.get("upgrade_points", 0))
	round_energy_bonus = 0
	set_energy(max_energy)


func get_age_years() -> int:
	# Share the calendar used by the bedroom, seasonal events and social stories.
	return preload("res://scripts/round_calendar.gd").age(round_number)


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
	add_mental_stat_experience(int(effects.get("intelligence", 0)), int(effects.get("emotional_intelligence", 0)))
	physical_strength += int(effects.get("physical_strength", 0))
	upgrade_points += int(effects.get("upgrade_points", 0))
	set_energy(current_energy + int(effects.get("current_energy", 0)), true)
	return true


@warning_ignore("integer_division")
func add_mental_stat_experience(intelligence_gain: int, emotional_gain: int) -> void:
	var bonus := mental_stat_bonus_units(intelligence_gain, emotional_gain)
	# Carry fractional bonuses between rewards so small gains still count.
	_mental_stat_bonus_remainder = Vector2i(bonus.x % 100, bonus.y % 100)
	intelligence += intelligence_gain + bonus.x / 100
	emotional_intelligence += emotional_gain + bonus.y / 100


@warning_ignore("integer_division")
func preview_mental_stat_gain(intelligence_gain: int, emotional_gain: int) -> Vector2i:
	var bonus := mental_stat_bonus_units(intelligence_gain, emotional_gain)
	return Vector2i(intelligence_gain + bonus.x / 100, emotional_gain + bonus.y / 100)


func mental_stat_bonus_units(intelligence_gain: int, emotional_gain: int) -> Vector2i:
	if not owned_products.has(ShopProducts.MALE_UNIFORM_ID):
		return Vector2i.ZERO
	var positive_gains := Vector2i(maxi(0, intelligence_gain), maxi(0, emotional_gain))
	return _mental_stat_bonus_remainder + positive_gains * ShopProducts.MALE_UNIFORM_STAT_BONUS


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
	add_mental_stat_experience(int(effects.get("intelligence", 0)), int(effects.get("emotional_intelligence", 0)))
	intelligence = maxi(0, intelligence)
	emotional_intelligence = maxi(0, emotional_intelligence)
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


func record_free_chat_affection(character: String) -> int:
	if character not in known_social_characters():
		return 0
	var earned: int = free_chat_affection_this_round.get(character, 0)
	var gain := mini(FREE_CHAT_AFFECTION_GAIN, mini(FREE_CHAT_AFFECTION_ROUND_CAP - earned, MAX_AFFECTION - affection_total(character)))
	if gain <= 0:
		return 0
	free_chat_affection_this_round[character] = earned + gain
	character_affection[character] = affection_total(character) + gain
	changed.emit()
	return gain


func yue_story_chapter() -> SocialCharacters.YueChapter:
	var affection_level := affection_progress(SocialCharacters.YUE).x
	if RoundCalendar.is_final_exam(round_number) and not final_exam_started and not yue_final_promise_seen and affection_level >= SocialCharacters.FINAL_PROMISE_AFFECTION_LEVEL:
		return SocialCharacters.YueChapter.FINAL_PROMISE
	# Saves from before the second card was added can still make its one-time choice.
	if yue_goldfish_seen and yue_story_card_offer(SocialCharacters.YueChapter.GOLDFISH) >= 0:
		return SocialCharacters.YueChapter.GOLDFISH
	return SocialCharacters.yue_park_chapter(round_number, park_meeting_seen, yue_goldfish_seen, yue_farewell_seen, affection_level, not romantic_partner.is_empty())


func finish_yue_story(chapter: SocialCharacters.YueChapter, add_story_card: bool) -> void:
	if chapter == SocialCharacters.YueChapter.NONE or chapter != yue_story_chapter():
		return
	resolve_yue_story_card(chapter, add_story_card)
	match chapter:
		SocialCharacters.YueChapter.FIRST_MEETING: park_meeting_seen = true
		SocialCharacters.YueChapter.GOLDFISH: yue_goldfish_seen = true
		SocialCharacters.YueChapter.FAREWELL: yue_farewell_seen = true
		SocialCharacters.YueChapter.CONFESSION: romantic_partner = SocialCharacters.YUE
		SocialCharacters.YueChapter.FINAL_PROMISE: yue_final_promise_seen = true
	changed.emit()


func yue_story_card_offer(chapter_index: int) -> int:
	if chapter_index == SocialCharacters.YueChapter.FINAL_PROMISE:
		return -1 if yue_final_promise_seen else CardCatalog.yue_story_card(chapter_index)
	return CardCatalog.yue_story_card(chapter_index) if chapter_index == _yue_story_cards_resolved else -1


func resolve_yue_story_card(chapter_index: int, add_to_deck: bool) -> void:
	var card_id := yue_story_card_offer(chapter_index)
	if card_id < 0:
		return
	if chapter_index != SocialCharacters.YueChapter.FINAL_PROMISE:
		_yue_story_cards_resolved += 1
	if add_to_deck:
		add_story_card(card_id)


func add_story_card(card_id: int) -> void:
	if not card_deck.any(func(existing_id: int) -> bool: return card_base_id(existing_id) == card_id):
		card_deck.append(card_id)


func known_social_characters() -> Array[String]:
	var known := SocialCharacters.known_characters(park_meeting_seen, fushimi_pen_seen)
	if shirakawa_first_story_seen:
		known.append(SocialCharacters.SHIRAKAWA)
	return known


func affection_gift_targets() -> Array[String]:
	return known_social_characters().filter(func(character: String) -> bool:
		return affection_total(character) < MAX_AFFECTION
	)


func try_buy_affection_gift(character: String, price: int, amount: int) -> int:
	if price < 0 or amount <= 0 or money < price or character not in affection_gift_targets():
		return 0
	var current := affection_total(character)
	var gain := mini(amount, MAX_AFFECTION - current)
	money -= price
	character_affection[character] = current + gain
	changed.emit()
	return gain


func social_locations() -> Dictionary[String, String]:
	var locations := SocialCharacters.locations_for_round(round_number, park_meeting_seen, yue_story_chapter(), fushimi_pen_seen)
	if available_daoxiang_act() > 0:
		locations[SocialCharacters.DAOXIANG] = SocialCharacters.PARK
	if shirakawa_first_story_seen or shirakawa_story_available():
		locations[SocialCharacters.SHIRAKAWA] = SocialCharacters.SCHOOL
	return locations


func has_character_story(character: String, location: String) -> bool:
	if character == SocialCharacters.DAOXIANG:
		return location == SocialCharacters.PARK and available_daoxiang_act() > 0
	if character == SocialCharacters.FUSHIMI:
		return location == SocialCharacters.SCHOOL and fushimi_story_chapter() != SocialCharacters.FushimiChapter.NONE
	if character == SocialCharacters.SHIRAKAWA:
		return location == SocialCharacters.SCHOOL and (
			shirakawa_story_available() or shirakawa_second_story_available() or shirakawa_third_story_available()
			or shirakawa_confession_available() or shirakawa_snow_available()
		)
	return SocialCharacters.has_story(character, location, yue_story_chapter())


func shirakawa_story_available() -> bool:
	return not shirakawa_first_story_seen and RoundCalendar.age(round_number) == RoundCalendar.HIGH_SCHOOL_AGE


func finish_shirakawa_first_story() -> void:
	if not shirakawa_story_available():
		return
	shirakawa_first_story_seen = true
	changed.emit()


func shirakawa_second_story_available() -> bool:
	return shirakawa_first_story_seen and not shirakawa_second_story_seen and (
		RoundCalendar.age(round_number) >= RoundCalendar.HIGH_SCHOOL_AGE
		and affection_progress(SocialCharacters.SHIRAKAWA).x >= 2
	)


func finish_shirakawa_second_story() -> void:
	if shirakawa_second_story_available():
		shirakawa_second_story_seen = true
		changed.emit()


func shirakawa_third_story_available() -> bool:
	return shirakawa_first_story_seen and shirakawa_second_story_seen and not shirakawa_third_story_seen and (
		RoundCalendar.age(round_number) >= RoundCalendar.HIGH_SCHOOL_AGE
		and affection_progress(SocialCharacters.SHIRAKAWA).x >= 5
	)


func finish_shirakawa_third_story() -> void:
	if shirakawa_third_story_available():
		shirakawa_third_story_seen = true
		changed.emit()


func shirakawa_confession_available() -> bool:
	return shirakawa_first_story_seen and shirakawa_second_story_seen and shirakawa_third_story_seen and (
		not shirakawa_confession_seen and romantic_partner.is_empty()
		and RoundCalendar.age(round_number) >= RoundCalendar.HIGH_SCHOOL_AGE
		and affection_progress(SocialCharacters.SHIRAKAWA).x >= 8
	)


func finish_shirakawa_confession() -> void:
	if shirakawa_confession_available():
		shirakawa_confession_seen = true
		romantic_partner = SocialCharacters.SHIRAKAWA
		changed.emit()


func shirakawa_snow_available() -> bool:
	return shirakawa_first_story_seen and shirakawa_second_story_seen and shirakawa_third_story_seen and shirakawa_confession_seen and (
		not shirakawa_snow_seen and RoundCalendar.is_final_exam(round_number) and not final_exam_started
		and affection_progress(SocialCharacters.SHIRAKAWA).x >= SocialCharacters.FINAL_PROMISE_AFFECTION_LEVEL
	)


func finish_shirakawa_snow() -> void:
	if shirakawa_snow_available():
		shirakawa_snow_seen = true
		changed.emit()


func fushimi_story_chapter() -> SocialCharacters.FushimiChapter:
	if not fushimi_pen_seen:
		return SocialCharacters.FushimiChapter.PEN if SocialCharacters.fushimi_pen_available(round_number) else SocialCharacters.FushimiChapter.NONE
	var affection_level := affection_progress(SocialCharacters.FUSHIMI).x
	if RoundCalendar.is_final_exam(round_number) and not final_exam_started and not fushimi_final_promise_seen and affection_level >= SocialCharacters.FINAL_PROMISE_AFFECTION_LEVEL:
		return SocialCharacters.FushimiChapter.FINAL_PROMISE
	if not fushimi_pen_card_resolved:
		return SocialCharacters.FushimiChapter.PEN
	var age := RoundCalendar.age(round_number)
	if age == SocialCharacters.FUSHIMI_TUTORING_AGE and not fushimi_tutoring_seen and affection_level >= SocialCharacters.FUSHIMI_TUTORING_AFFECTION_LEVEL:
		return SocialCharacters.FushimiChapter.TUTORING
	var bookshop_age := age >= RoundCalendar.MIDDLE_SCHOOL_AGE and age <= SocialCharacters.FUSHIMI_BOOKSHOP_MAX_AGE
	if bookshop_age and not fushimi_bookshop_seen and affection_level >= SocialCharacters.FUSHIMI_BOOKSHOP_AFFECTION_LEVEL:
		return SocialCharacters.FushimiChapter.BOOKSHOP
	if age == SocialCharacters.FUSHIMI_CONFESSION_AGE and affection_level >= SocialCharacters.FUSHIMI_CONFESSION_AFFECTION_LEVEL and romantic_partner.is_empty() and not fushimi_confession_seen:
		return SocialCharacters.FushimiChapter.CONFESSION
	return SocialCharacters.FushimiChapter.NONE


func finish_fushimi_story(chapter: SocialCharacters.FushimiChapter, add_to_deck: bool) -> void:
	if chapter == SocialCharacters.FushimiChapter.NONE or chapter != fushimi_story_chapter():
		return
	match chapter:
		SocialCharacters.FushimiChapter.PEN:
			fushimi_pen_seen = true
			fushimi_pen_card_resolved = true
		SocialCharacters.FushimiChapter.TUTORING:
			fushimi_tutoring_seen = true
		SocialCharacters.FushimiChapter.BOOKSHOP:
			fushimi_bookshop_seen = true
		SocialCharacters.FushimiChapter.CONFESSION:
			fushimi_confession_seen = true
			romantic_partner = SocialCharacters.FUSHIMI
		SocialCharacters.FushimiChapter.FINAL_PROMISE:
			fushimi_final_promise_seen = true
	if add_to_deck:
		add_story_card(CardCatalog.fushimi_story_card(chapter))
	changed.emit()


func try_socialize(character: String) -> bool:
	if character not in known_social_characters() or current_energy < SocialCharacters.CHAT_ENERGY_COST:
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
		"intelligence": add_mental_stat_experience(amount, 0)
		"emotional_intelligence": add_mental_stat_experience(0, amount)
		"physical_strength": physical_strength += amount
		_:
			push_error("Unknown game reward: %s" % stat)
			return
	changed.emit()


func game_aesthetic_target() -> int:
	return GameAesthetic.target_points(game_aesthetic_rewards_claimed)


func game_aesthetic_gain(game_id: String, price: int) -> int:
	if not GameAesthetic.contains_game(game_id):
		return 0
	var completed_plays: int = game_play_counts.get(game_id, 0)
	return GameAesthetic.gain(price, completed_plays)


func record_game_play(game_id: String, price: int) -> Dictionary:
	if not owns_game(game_id) or not GameAesthetic.contains_game(game_id) or price <= 0:
		return {"gain": 0, "reward_unlocked": false}
	var gain := game_aesthetic_gain(game_id, price)
	game_aesthetic_points += gain
	game_play_counts[game_id] = game_play_counts.get(game_id, 0) + 1
	var target := game_aesthetic_target()
	var reward_unlocked := game_aesthetic_points >= target
	if reward_unlocked:
		game_aesthetic_points -= target
		game_aesthetic_rewards_claimed += 1
		set_max_energy(max_energy + 2, true)
	else:
		changed.emit()
	return {"gain": gain, "reward_unlocked": reward_unlocked}


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
	add_mental_stat_experience(intelligence_gain, emotional_gain)
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


func try_apply_map_activity(activity: MapActivity, companion: String = "") -> bool:
	if not can_apply_map_activity(activity):
		return false
	if activity.affection_gain > 0 and companion not in known_social_characters():
		return false
	if activity.cooldown_rounds > 0 and not activity.cooldown_id.is_empty():
		_activity_available_rounds[activity.cooldown_id] = round_number + activity.cooldown_rounds
	money += activity.money_change
	physical_strength += activity.physical_gain
	max_health += activity.max_health_gain
	if activity.affection_gain > 0:
		character_affection[companion] = mini(affection_total(companion) + activity.affection_gain, MAX_AFFECTION)
	set_energy(current_energy + activity.energy_change, activity.energy_change > 0)
	return true
