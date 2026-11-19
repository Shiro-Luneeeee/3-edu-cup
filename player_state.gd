extends Node

signal changed

const DEFAULT_MAX_ENERGY := 20
const DEFAULT_MONEY := 500
const ROUND_ALLOWANCE := 60

var max_energy := DEFAULT_MAX_ENERGY
var current_energy := DEFAULT_MAX_ENERGY
var round_number := 1
var intelligence := 0
var emotional_intelligence := 0
var physical_strength := 0
var upgrade_points := 0
var money := DEFAULT_MONEY
var owned_products: Array[String] = []

var _initialized := false


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
	round_number = 1
	intelligence = 0
	emotional_intelligence = 0
	physical_strength = 0
	upgrade_points = 0
	money = DEFAULT_MONEY
	owned_products.clear()
	set_max_energy(DEFAULT_MAX_ENERGY, true)


func make_snapshot() -> Dictionary:
	return {
		"max_energy": max_energy,
		"current_energy": current_energy,
		"round_number": round_number,
		"intelligence": intelligence,
		"emotional_intelligence": emotional_intelligence,
		"physical_strength": physical_strength,
		"upgrade_points": upgrade_points,
		"money": money,
		"owned_products": owned_products.duplicate(),
	}


func restore_snapshot(data: Dictionary) -> void:
	max_energy = maxi(1, int(data.get("max_energy", DEFAULT_MAX_ENERGY)))
	current_energy = clampi(int(data.get("current_energy", max_energy)), 0, max_energy)
	round_number = maxi(1, int(data.get("round_number", 1)))
	intelligence = maxi(0, int(data.get("intelligence", 0)))
	emotional_intelligence = maxi(0, int(data.get("emotional_intelligence", 0)))
	physical_strength = maxi(0, int(data.get("physical_strength", 0)))
	upgrade_points = maxi(0, int(data.get("upgrade_points", 0)))
	money = maxi(0, int(data.get("money", DEFAULT_MONEY)))
	owned_products.clear()
	for product_id in data.get("owned_products", []):
		if product_id is String and not owned_products.has(product_id):
			owned_products.append(product_id)
	_initialized = true
	changed.emit()


func advance_round() -> void:
	round_number += 1
	money += ROUND_ALLOWANCE
	set_energy(max_energy)


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
	max_energy = maxi(1, max_energy + int(effects.get("max_energy", 0)))
	current_energy = clampi(current_energy + int(effects.get("current_energy", 0)), 0, max_energy)
	changed.emit()
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
	current_energy -= energy_cost
	changed.emit()
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


func set_energy(value: int) -> void:
	current_energy = clampi(value, 0, max_energy)
	changed.emit()


func set_max_energy(value: int, refill: bool = false) -> void:
	max_energy = maxi(1, value)
	set_energy(max_energy if refill else current_energy)


func try_apply_action(energy_cost: int, intelligence_gain: int, emotional_gain: int, upgrade_point_gain: int) -> bool:
	if energy_cost < 0 or current_energy < energy_cost:
		return false
	current_energy -= energy_cost
	intelligence += intelligence_gain
	emotional_intelligence += emotional_gain
	upgrade_points += upgrade_point_gain
	changed.emit()
	return true
