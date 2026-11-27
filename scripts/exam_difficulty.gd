extends RefCounted

const FIRST_PROGRESS_TARGET := 100
const PROGRESS_PER_WIN := 1
const YEARS_PER_HEALTH_LOSS_BONUS := 6
const GUARANTEED_NEGATIVE_HEALTH_RATIO := 0.2
const RoundCalendar := preload("res://scripts/round_calendar.gd")


static func progress_target(passed_exams: int) -> int:
	return FIRST_PROGRESS_TARGET + passed_exams * PROGRESS_PER_WIN


@warning_ignore("integer_division")
static func turn_end_age_bonus(age: int) -> int:
	return maxi(0, age - RoundCalendar.START_AGE) / YEARS_PER_HEALTH_LOSS_BONUS


static func negative_draw_chance(health: float, max_health: int) -> float:
	var health_ratio := health / max_health
	return clampf((1.0 - health_ratio) / (1.0 - GUARANTEED_NEGATIVE_HEALTH_RATIO), 0.0, 1.0)
