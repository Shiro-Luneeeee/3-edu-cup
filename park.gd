extends "res://map_activity.gd"

const RoundCalendar := preload("res://round_calendar.gd")
const MEETING_SCENE := preload("res://park_meeting.tscn")
const ParkMeeting := preload("res://park_meeting.gd")

# The hit area follows the foreground path and cuts around the bench and pond curb.
const ROAD_POINTS := [
	Vector2(397, 603), Vector2(436, 575), Vector2(497, 549), Vector2(560, 530),
	Vector2(627, 514), Vector2(706, 501), Vector2(777, 490), Vector2(841, 484),
	Vector2(906, 481), Vector2(949, 480), Vector2(904, 492), Vector2(851, 494),
	Vector2(792, 503), Vector2(740, 514), Vector2(703, 531), Vector2(684, 548),
	Vector2(677, 565), Vector2(699, 585), Vector2(739, 608), Vector2(837, 649),
	Vector2(988, 705), Vector2(1169, 769), Vector2(1330, 820), Vector2(1506, 869),
	Vector2(1670, 915), Vector2(1670, 941), Vector2(337, 941), Vector2(314, 891),
	Vector2(291, 850), Vector2(280, 809), Vector2(313, 815), Vector2(348, 819),
	Vector2(356, 849), Vector2(368, 862), Vector2(383, 856), Vector2(377, 829),
	Vector2(369, 776), Vector2(375, 752), Vector2(421, 728), Vector2(486, 692),
	Vector2(496, 723), Vector2(504, 751), Vector2(522, 745), Vector2(514, 714),
	Vector2(510, 669), Vector2(523, 662), Vector2(521, 651), Vector2(497, 644),
	Vector2(506, 629), Vector2(502, 615), Vector2(487, 604), Vector2(464, 602),
	Vector2(432, 605), Vector2(408, 607),
]

var meeting: ParkMeeting


func _ready() -> void:
	var jogging := Activity.new()
	jogging.hotspot_points = PackedVector2Array(ROAD_POINTS)
	jogging.status_text = "慢跑中..."
	jogging.physical_gain = 10
	activities.append(jogging)
	super._ready()
	if RoundCalendar.age(PlayerState.round_number) == 5 and not PlayerState.park_meeting_seen:
		meeting = MEETING_SCENE.instantiate() as ParkMeeting
		meeting.completed.connect(finish_meeting)
		add_child(meeting)


func finish_meeting() -> void:
	PlayerState.park_meeting_seen = true
	meeting.queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(meeting):
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)
