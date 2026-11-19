extends Node

signal changed

const DEFAULT_MAX_ENERGY := 20

var max_energy := DEFAULT_MAX_ENERGY
var current_energy := DEFAULT_MAX_ENERGY
var round_number := 1
var intelligence := 0
var emotional_intelligence := 0
var physical_strength := 0
var upgrade_points := 0

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
	set_max_energy(DEFAULT_MAX_ENERGY, true)


func advance_round() -> void:
	round_number += 1
	set_energy(max_energy)


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
