extends RefCounted

enum YueChapter { NONE = -1, FIRST_MEETING = 0, GOLDFISH = 1, FAREWELL = 2, CONFESSION = 3, FINAL_PROMISE = 4 }
enum FushimiChapter { NONE = -1, PEN = 0, TUTORING = 1, BOOKSHOP = 2, CONFESSION = 3, FINAL_PROMISE = 4 }

const RoundCalendar := preload("res://scripts/round_calendar.gd")
const YUE := "月侧阳奈里"
const FUSHIMI := "伏见宫夜姬"
const SHIRAKAWA := "白川花雪"
const PARK := "res://scenes/park.tscn"
const SCHOOL := "res://scenes/classroom.tscn"
const FIRST_MEETING_AGE := 5
const GOLDFISH_AGE := 10
const GOLDFISH_AFFECTION_LEVEL := 2
const FAREWELL_AGE := 13
const FAREWELL_AFFECTION_LEVEL := 5
const CONFESSION_MIN_AGE := 14
const CONFESSION_MAX_AGE := 15
const CONFESSION_AFFECTION_LEVEL := 8
const FINAL_PROMISE_AFFECTION_LEVEL := 10
const FUSHIMI_PEN_STORY_MAX_AGE := 8
const FUSHIMI_TUTORING_AGE := 10
const FUSHIMI_TUTORING_AFFECTION_LEVEL := 2
const FUSHIMI_BOOKSHOP_MAX_AGE := 14
const FUSHIMI_BOOKSHOP_AFFECTION_LEVEL := 5
const FUSHIMI_CONFESSION_AGE := 16
const FUSHIMI_CONFESSION_AFFECTION_LEVEL := 8
const CHAT_ENERGY_COST := 5
const CHAT_AFFECTION_GAIN := 10
const AVATAR_PATHS := {
	YUE: "res://images/character/yue_chibi.png",
	FUSHIMI: "res://images/character/fushimi_chibi.png",
	SHIRAKAWA: "res://images/character/shirakawa_chibi.png",
}


static func avatar(character: String) -> Texture2D:
	return load(AVATAR_PATHS[character]) as Texture2D


static func known_characters(park_meeting_seen: bool, fushimi_pen_seen: bool) -> Array[String]:
	var known: Array[String] = []
	if park_meeting_seen:
		known.append(YUE)
	if fushimi_pen_seen:
		known.append(FUSHIMI)
	return known


static func locations_for_round(round_number: int, park_meeting_seen: bool, yue_chapter: YueChapter, fushimi_pen_seen: bool) -> Dictionary[String, String]:
	var age := RoundCalendar.age(round_number)
	var result: Dictionary[String, String] = {}
	if age >= FIRST_MEETING_AGE:
		var at_school := yue_chapter == YueChapter.FINAL_PROMISE or (age >= RoundCalendar.SCHOOL_AGE and park_meeting_seen and yue_chapter == YueChapter.NONE)
		result[YUE] = SCHOOL if at_school else PARK
	if fushimi_pen_seen or fushimi_pen_available(round_number):
		result[FUSHIMI] = SCHOOL
	return result


static func fushimi_pen_available(round_number: int) -> bool:
	var age := RoundCalendar.age(round_number)
	return age >= RoundCalendar.SCHOOL_AGE and age <= FUSHIMI_PEN_STORY_MAX_AGE


static func yue_park_chapter(round_number: int, park_meeting_seen: bool, goldfish_seen: bool, farewell_seen: bool, affection_level: int, has_partner: bool) -> YueChapter:
	var age := RoundCalendar.age(round_number)
	if not park_meeting_seen and age >= FIRST_MEETING_AGE:
		return YueChapter.FIRST_MEETING
	if park_meeting_seen and not goldfish_seen and age == GOLDFISH_AGE and affection_level >= GOLDFISH_AFFECTION_LEVEL:
		return YueChapter.GOLDFISH
	if goldfish_seen and not farewell_seen and age == FAREWELL_AGE and affection_level >= FAREWELL_AFFECTION_LEVEL:
		return YueChapter.FAREWELL
	var confession_age := age >= CONFESSION_MIN_AGE and age <= CONFESSION_MAX_AGE
	if farewell_seen and not has_partner and confession_age and affection_level >= CONFESSION_AFFECTION_LEVEL:
		return YueChapter.CONFESSION
	return YueChapter.NONE


static func has_story(character: String, location: String, yue_chapter: YueChapter) -> bool:
	var story_location := SCHOOL if yue_chapter == YueChapter.FINAL_PROMISE else PARK
	return character == YUE and location == story_location and yue_chapter != YueChapter.NONE
