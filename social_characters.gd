extends RefCounted

const RoundCalendar := preload("res://round_calendar.gd")
const YUE := "月侧阳奈里"
const PARK := "res://park.tscn"
const SCHOOL := "res://classroom.tscn"
const FIRST_MEETING_AGE := 5
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


static func locations_for_round(round_number: int, park_meeting_seen: bool) -> Dictionary[String, String]:
	var age := RoundCalendar.age(round_number)
	var result: Dictionary[String, String] = {}
	if age >= FIRST_MEETING_AGE:
		result[YUE] = SCHOOL if age >= RoundCalendar.SCHOOL_AGE and park_meeting_seen else PARK
	return result


static func has_story(character: String, location: String, round_number: int, park_meeting_seen: bool) -> bool:
	return character == YUE and location == PARK and not park_meeting_seen and RoundCalendar.age(round_number) >= FIRST_MEETING_AGE
