extends RefCounted

enum Season { NONE, SPRING, SUMMER, AUTUMN, WINTER }

const START_AGE := 4
const SCHOOL_AGE := 7
const FIRST_SCHOOL_ROUND := SCHOOL_AGE - START_AGE + 1
const ROUNDS_PER_YEAR := 4
const FINAL_EXAM_ROUND := FIRST_SCHOOL_ROUND + (18 - SCHOOL_AGE) * ROUNDS_PER_YEAR + 3
const SEASON_NAMES := ["", "春天", "夏天", "秋天", "冬天"]
const GRADES := [
	"小学一年级", "小学二年级", "小学三年级", "小学四年级", "小学五年级", "小学六年级",
	"初中一年级", "初中二年级", "初中三年级",
	"高中一年级", "高中二年级", "高中三年级",
]


@warning_ignore("integer_division")
static func age(round_number: int) -> int:
	if round_number < FIRST_SCHOOL_ROUND:
		return START_AGE + maxi(0, round_number - 1)
	return SCHOOL_AGE + (round_number - FIRST_SCHOOL_ROUND) / ROUNDS_PER_YEAR


static func first_round_at_age(target_age: int) -> int:
	if target_age < SCHOOL_AGE:
		return maxi(1, target_age - START_AGE + 1)
	return FIRST_SCHOOL_ROUND + (target_age - SCHOOL_AGE) * ROUNDS_PER_YEAR


static func season(round_number: int) -> Season:
	if round_number <= 1:
		return Season.NONE
	if round_number < FIRST_SCHOOL_ROUND:
		return Season.SPRING if round_number == 2 else Season.SUMMER
	var school_season := (round_number - FIRST_SCHOOL_ROUND + 2) % ROUNDS_PER_YEAR
	return (Season.SPRING + school_season) as Season


static func is_final_exam(round_number: int) -> bool:
	return round_number == FINAL_EXAM_ROUND


static func has_card_match(round_number: int) -> bool:
	if round_number >= FINAL_EXAM_ROUND:
		return is_final_exam(round_number)
	if round_number < FIRST_SCHOOL_ROUND:
		return true
	var current_season := season(round_number)
	return current_season != Season.SUMMER and current_season != Season.WINTER


static func grade(current_age: int) -> String:
	var index := current_age - SCHOOL_AGE
	if index < 0:
		return "学龄前"
	if index < GRADES.size():
		return GRADES[index]
	return "高中毕业"


static func season_and_grade(round_number: int) -> String:
	var season_name: String = SEASON_NAMES[season(round_number)]
	var grade_name := grade(age(round_number))
	if is_final_exam(round_number):
		return "%s  ·  %s  ·  高考" % [season_name, grade_name]
	return grade_name if season_name.is_empty() else "%s  ·  %s" % [season_name, grade_name]
