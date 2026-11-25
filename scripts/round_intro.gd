extends Control

const RoundCalendar := preload("res://scripts/round_calendar.gd")
const BACKGROUNDS := [
	"res://images/bedroom.png",
	"res://images/seasons/spring.png",
	"res://images/seasons/summer.png",
	"res://images/seasons/autumn.png",
	"res://images/seasons/winter.png",
]


func show_round(round_number: int) -> void:
	%Background.texture = load(BACKGROUNDS[RoundCalendar.season(round_number)]) as Texture2D
	%Age.text = "%d 岁" % RoundCalendar.age(round_number)
	%Details.text = RoundCalendar.season_and_grade(round_number)
