extends Node

signal changed

enum Subject { CHINESE, MATH, ENGLISH }

const EXPERIENCE_PER_LEVEL := 20
const ACTION_ENERGY_COST := 5
const ACTION_REWARD := 10
const ACTION_EXPERIENCE := 10

var _total_experience: Array[int] = [0, 0, 0]


func reset() -> void:
	_total_experience.fill(0)
	changed.emit()


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


@warning_ignore("integer_division")
func get_level(subject: Subject) -> int:
	return _total_experience[subject] / EXPERIENCE_PER_LEVEL


func get_experience(subject: Subject) -> int:
	return _total_experience[subject] % EXPERIENCE_PER_LEVEL
