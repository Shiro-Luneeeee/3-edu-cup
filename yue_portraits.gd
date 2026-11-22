extends RefCounted

enum Mood { CHEERFUL, WORRIED, PROUD, LAUGHING, PUZZLED, POUTING, WINKING }

const RoundCalendar := preload("res://round_calendar.gd")
const CHILD_SHEET := "res://images/character/yue_child_expressions.png"
const SCHOOL_SHEET := "res://images/character/yue_school_expressions.png"
const AGE_SHEET := "res://images/character/yue_age_portraits.jpg"
const ONSITE_SCHOOL := "res://images/character/yue_onsite_school.png"
const ONSITE_OLDER := "res://images/character/yue_onsite_older.png"
const BLACK_KEY := preload("res://portrait_black_key.gdshader")
const CHILD_REGIONS := [Rect2(119, 0, 712, 877), Rect2(978, 0, 712, 877)]
const SCHOOL_REGIONS := {
	Mood.CHEERFUL: Rect2(68, 0, 416, 512),
	Mood.PROUD: Rect2(576, 0, 416, 512),
	Mood.LAUGHING: Rect2(1084, 0, 416, 512),
	Mood.PUZZLED: Rect2(68, 512, 416, 512),
	Mood.POUTING: Rect2(576, 512, 416, 512),
	Mood.WINKING: Rect2(1084, 512, 416, 512),
}
const OLDER_AGES := [13, 16, 19]
const AGE_REGIONS := [
	Rect2(489, 32, 224, 303),
	Rect2(743, 2, 227, 277),
	Rect2(985, 0, 253, 308),
]
const ONSITE_CHILD_REGION := Rect2(119, 0, 712, 867)
const ONSITE_OLDER_REGIONS := [
	Rect2(75, 0, 550, 722),
	Rect2(675, 0, 510, 722),
	Rect2(1225, 0, 590, 722),
]


static func show_on(target: TextureRect, age: int, mood: Mood = Mood.CHEERFUL) -> void:
	if age < RoundCalendar.SCHOOL_AGE:
		set_portrait(target, CHILD_SHEET, CHILD_REGIONS[1 if mood == Mood.WORRIED else 0])
	elif age < OLDER_AGES[0]:
		set_portrait(target, SCHOOL_SHEET, SCHOOL_REGIONS.get(mood, SCHOOL_REGIONS[Mood.CHEERFUL]))
	else:
		var index := OLDER_AGES.bsearch(age, false) - 1
		show_age_region(target, AGE_REGIONS[index])


static func show_onsite(target: TextureRect, age: int) -> void:
	if age < RoundCalendar.SCHOOL_AGE:
		set_portrait(target, CHILD_SHEET, ONSITE_CHILD_REGION)
	elif age < OLDER_AGES[0]:
		target.texture = load(ONSITE_SCHOOL) as Texture2D
		target.material = null
	else:
		var index := OLDER_AGES.bsearch(age, false) - 1
		set_portrait(target, ONSITE_OLDER, ONSITE_OLDER_REGIONS[index])


static func show_age_region(target: TextureRect, region: Rect2) -> void:
	var material := ShaderMaterial.new()
	material.shader = BLACK_KEY
	set_portrait(target, AGE_SHEET, region, material)


static func set_portrait(target: TextureRect, sheet: String, region: Rect2, material: ShaderMaterial = null) -> void:
	var portrait := AtlasTexture.new()
	portrait.filter_clip = true
	portrait.atlas = load(sheet) as Texture2D
	portrait.region = region
	target.material = material
	target.texture = portrait
