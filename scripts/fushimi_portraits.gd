extends RefCounted

enum Mood { CALM, ASKING, EXPLAINING, STARTLED, SMILING, FOCUSED }

const SCHOOL_SHEET := "res://images/character/fushimi_school_expressions.png"
const OLDER_SHEET := "res://images/character/fushimi_older_portraits.png"
const MIDDLE_SCHOOL_AGE := 13
const HIGH_SCHOOL_AGE := 16
const SCHOOL_REGIONS := {
	Mood.CALM: Rect2(66, 0, 416, 500),
	Mood.ASKING: Rect2(560, 0, 416, 500),
	Mood.EXPLAINING: Rect2(1074, 0, 416, 500),
	Mood.STARTLED: Rect2(66, 512, 416, 500),
	Mood.SMILING: Rect2(560, 512, 416, 500),
	Mood.FOCUSED: Rect2(1074, 512, 416, 500),
}
const OLDER_REGIONS := [Rect2(132, 0, 650, 887), Rect2(1019, 0, 650, 887)]


static func show_school(target: TextureRect, mood: Mood) -> void:
	set_region(target, SCHOOL_SHEET, SCHOOL_REGIONS[mood])


static func show_on(target: TextureRect, age: int) -> void:
	if age < MIDDLE_SCHOOL_AGE:
		show_school(target, Mood.SMILING)
	else:
		var index := 1 if age >= HIGH_SCHOOL_AGE else 0
		set_region(target, OLDER_SHEET, OLDER_REGIONS[index])


static func set_region(target: TextureRect, sheet: String, region: Rect2) -> void:
	var portrait := AtlasTexture.new()
	portrait.atlas = load(sheet) as Texture2D
	portrait.region = region
	portrait.filter_clip = true
	target.material = null
	target.texture = portrait
