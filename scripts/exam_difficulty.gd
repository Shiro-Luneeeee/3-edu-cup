extends RefCounted

const FIRST_PROGRESS_TARGET := 100
const PROGRESS_PER_WIN := 2
const WINS_PER_DAMAGE_BONUS := 6
const MAX_DAMAGE_BONUS := 3
enum Attack { DIRECT_HIT, HAND_DISCARD, SLOT_LOCK, ENERGY_LOSS, EXAM_ANXIETY, HAND_RETURN }

const BASE_ATTACK_DAMAGE := [6, 4, 4, 4, 4, 4]


static func progress_target(passed_exams: int) -> int:
	return FIRST_PROGRESS_TARGET + passed_exams * PROGRESS_PER_WIN


@warning_ignore("integer_division")
static func damage_bonus(passed_exams: int) -> int:
	return mini(passed_exams / WINS_PER_DAMAGE_BONUS, MAX_DAMAGE_BONUS)


static func attack_damage(attack: int, bonus: int) -> int:
	var base_damage: int = BASE_ATTACK_DAMAGE[attack]
	return base_damage if attack in [Attack.EXAM_ANXIETY, Attack.HAND_RETURN] else base_damage + bonus
