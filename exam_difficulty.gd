extends RefCounted

const FIRST_PROGRESS_TARGET := 100
const PROGRESS_PER_WIN := 3
const WINS_PER_DAMAGE_BONUS := 4
const MAX_DAMAGE_BONUS := 3
const BASE_ATTACK_DAMAGE := [6, 4, 4, 4]


static func progress_target(passed_exams: int) -> int:
	return FIRST_PROGRESS_TARGET + passed_exams * PROGRESS_PER_WIN


@warning_ignore("integer_division")
static func damage_bonus(passed_exams: int) -> int:
	return mini(passed_exams / WINS_PER_DAMAGE_BONUS, MAX_DAMAGE_BONUS)
