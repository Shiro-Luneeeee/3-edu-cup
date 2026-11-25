extends "res://scripts/map_activity.gd"

const MEETING_SCENE := preload("res://scenes/park_meeting.tscn")
const GOLDFISH_SCENE := preload("res://scenes/yue_goldfish.tscn")
const FAREWELL_SCENE := preload("res://scenes/yue_farewell.tscn")
const DAOXIANG_SCENE: PackedScene = preload("res://scenes/daoxiang_vn.tscn")
const CONFESSION_SCENE := preload("res://scenes/yue_confession.tscn")

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

var daoxiang_story: StoryDialogue


func _ready() -> void:
	var jogging := Activity.new()
	jogging.hotspot_points = PackedVector2Array(ROAD_POINTS)
	jogging.status_text = "慢跑中..."
	jogging.sound_effect_id = "running"
	jogging.physical_gain = 10
	activities.append(jogging)
	super._ready()


func can_open_character(character: String) -> bool:
	return not is_instance_valid(daoxiang_story) and not is_instance_valid(story) and not is_instance_valid(story_card_offer) and super.can_open_character(character)


func open_character(character: String) -> void:
	if character == SocialCharacters.DAOXIANG:
		var act := PlayerState.available_daoxiang_act()
		if act > 0 and can_open_character(character):
			SceneFade.play_action(show_daoxiang_story.bind(act))
		return
	var chapter := PlayerState.yue_story_chapter()
	if not SocialCharacters.has_story(character, scene_file_path, chapter):
		super.open_character(character)
		return
	if can_open_character(character):
		if chapter == SocialCharacters.YueChapter.GOLDFISH and PlayerState.yue_goldfish_seen:
			show_story_card_offer(chapter)
		elif chapter == SocialCharacters.YueChapter.CONFESSION:
			request_confession_confirmation(SocialCharacters.YUE, confirm_confession)
		else:
			var scene: PackedScene = [MEETING_SCENE, GOLDFISH_SCENE, FAREWELL_SCENE][chapter]
			SceneFade.play_action(show_story.bind(scene, chapter))


func confirm_confession(accepted: bool) -> void:
	if accepted and PlayerState.yue_story_chapter() == SocialCharacters.YueChapter.CONFESSION:
		SceneFade.play_action(show_story.bind(CONFESSION_SCENE, SocialCharacters.YueChapter.CONFESSION))


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(daoxiang_story):
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			get_viewport().set_input_as_handled()
			daoxiang_story.queue_free()
		return
	super._unhandled_key_input(event)


func show_daoxiang_story(act: int) -> void:
	daoxiang_story = DAOXIANG_SCENE.instantiate() as StoryDialogue
	daoxiang_story.set("act", act)
	daoxiang_story.completed.connect(finish_daoxiang_story.bind(act), CONNECT_ONE_SHOT)
	add_child(daoxiang_story)


func finish_daoxiang_story(act: int) -> void:
	PlayerState.complete_daoxiang_act(act)
	daoxiang_story.hide()
	daoxiang_story.queue_free()
