extends Node

signal changed

enum Subject { CHINESE, MATH, ENGLISH }

const CURVE_VERSION := 2
const FIRST_LEVEL_COST := 20
const LEVEL_COST_STEP := 5
const FIXED_COST_LEVEL := 10
const ACTION_ENERGY_COST := 5
const ACTION_REWARD := 10
const ACTION_EXPERIENCE := 10

var _total_experience: Array[int] = [0, 0, 0]


func reset() -> void:
	_total_experience.fill(0)
	changed.emit()


func make_snapshot() -> Dictionary:
	return {"total_experience": _total_experience.duplicate(), "curve_version": CURVE_VERSION}


func restore_snapshot(data: Dictionary) -> void:
	var values: Array = data.get("total_experience", [])
	var legacy_curve := int(data.get("curve_version", 1)) < CURVE_VERSION
	for index in _total_experience.size():
		var experience := maxi(0, int(values[index])) if index < values.size() else 0
		_total_experience[index] = migrate_experience(experience) if legacy_curve else experience
	changed.emit()


@warning_ignore("integer_division")
func migrate_experience(experience: int) -> int:
	var old_level := experience / FIRST_LEVEL_COST
	var rising_cost_levels := mini(old_level, FIXED_COST_LEVEL)
	var extra_steps := rising_cost_levels * (rising_cost_levels - 1) / 2
	extra_steps += maxi(0, old_level - FIXED_COST_LEVEL) * FIXED_COST_LEVEL
	return experience + extra_steps * LEVEL_COST_STEP


func perform_action(subject: Subject) -> bool:
	var intelligence_gain := ACTION_REWARD if subject == Subject.MATH else 0
	var emotional_gain := ACTION_REWARD if subject == Subject.CHINESE else 0
	var upgrade_point_gain := ACTION_REWARD if subject == Subject.ENGLISH else 0
	if not PlayerState.try_apply_action(ACTION_ENERGY_COST, intelligence_gain, emotional_gain, upgrade_point_gain):
		return false
	add_experience(subject, ACTION_EXPERIENCE)
	return true


func add_experience(subject: Subject, amount: int) -> void:
	if amount <= 0:
		return
	_total_experience[subject] += amount
	changed.emit()


func get_level(subject: Subject) -> int:
	return get_progress(subject).x


func required_experience(level: int) -> int:
	return FIRST_LEVEL_COST + mini(level, FIXED_COST_LEVEL) * LEVEL_COST_STEP


@warning_ignore("integer_division")
func get_progress(subject: Subject) -> Vector2i:
	var experience := _total_experience[subject]
	for level in FIXED_COST_LEVEL:
		var required := required_experience(level)
		if experience < required:
			return Vector2i(level, experience)
		experience -= required
	var fixed_cost := required_experience(FIXED_COST_LEVEL)
	return Vector2i(FIXED_COST_LEVEL + experience / fixed_cost, experience % fixed_cost)
