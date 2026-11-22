extends RefCounted

enum YueChapter { NONE = -1, FIRST_MEETING = 0, GOLDFISH = 1, FAREWELL = 2 }

const RoundCalendar := preload("res://round_calendar.gd")
const YUE := "月侧阳奈里"
const PARK := "res://park.tscn"
const SCHOOL := "res://classroom.tscn"
const FIRST_MEETING_AGE := 5
const GOLDFISH_AGE := 10
const GOLDFISH_AFFECTION_LEVEL := 2
const FAREWELL_AGE := 13
const FAREWELL_AFFECTION_LEVEL := 5
const CHAT_ENERGY_COST := 5
const CHAT_AFFECTION_GAIN := 10
const AVATAR_PATHS := {
	YUE: "res://images/character/yue_chibi.png",
}


static func avatar(character: String) -> Texture2D:
	return load(AVATAR_PATHS[character]) as Texture2D


static func known_characters(park_meeting_seen: bool) -> Array[String]:
	var known: Array[String] = []
	if park_meeting_seen:
		known.append(YUE)
	return known


static func locations_for_round(round_number: int, park_meeting_seen: bool, yue_chapter: YueChapter = YueChapter.NONE) -> Dictionary[String, String]:
	var age := RoundCalendar.age(round_number)
	var result: Dictionary[String, String] = {}
	if age >= FIRST_MEETING_AGE:
		var at_school := age >= RoundCalendar.SCHOOL_AGE and park_meeting_seen and yue_chapter == YueChapter.NONE
		result[YUE] = SCHOOL if at_school else PARK
	return result


static func yue_park_chapter(round_number: int, park_meeting_seen: bool, goldfish_seen: bool, farewell_seen: bool, affection_level: int) -> YueChapter:
	var age := RoundCalendar.age(round_number)
	if not park_meeting_seen and age >= FIRST_MEETING_AGE:
		return YueChapter.FIRST_MEETING
	if park_meeting_seen and not goldfish_seen and age == GOLDFISH_AGE and affection_level >= GOLDFISH_AFFECTION_LEVEL:
		return YueChapter.GOLDFISH
	if goldfish_seen and not farewell_seen and age == FAREWELL_AGE and affection_level >= FAREWELL_AFFECTION_LEVEL:
		return YueChapter.FAREWELL
	return YueChapter.NONE


static func has_story(character: String, location: String, yue_chapter: YueChapter) -> bool:
	return character == YUE and location == PARK and yue_chapter != YueChapter.NONE
