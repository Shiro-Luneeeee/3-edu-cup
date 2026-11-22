extends ColorRect

const SocialCharacters := preload("res://social_characters.gd")
const CharacterBadge := preload("res://character_badge.gd")
const SOCIAL_SCENE := preload("res://onsite_social.tscn")
const Social := preload("res://social.gd")

@onready var visitors: HBoxContainer = $Visitors

var visitor_ids: Array[String] = []
var visitor_stories: Array[String] = []
var social_overlay: Social


func _ready() -> void:
	PlayerState.changed.connect(refresh_visitors)
	refresh_visitors()


func refresh_visitors() -> void:
	var here: Array[String] = []
	var stories: Array[String] = []
	var yue_chapter := PlayerState.yue_park_chapter()
	var locations := SocialCharacters.locations_for_round(PlayerState.round_number, PlayerState.park_meeting_seen, yue_chapter)
	for character: String in locations:
		if locations[character] == scene_file_path:
			here.append(character)
			if SocialCharacters.has_story(character, scene_file_path, yue_chapter):
				stories.append(character)
	if here == visitor_ids and stories == visitor_stories:
		return
	visitor_ids = here
	visitor_stories = stories
	for child in visitors.get_children():
		visitors.remove_child(child)
		child.queue_free()
	for character in visitor_ids:
		var badge := CharacterBadge.new()
		badge.configure(SocialCharacters.avatar(character), character, 76.0, character in visitor_stories)
		badge.pressed.connect(open_character.bind(character))
		visitors.add_child(badge)


func can_open_character(character: String) -> bool:
	return character in visitor_ids and not is_instance_valid(social_overlay) and not SceneFade.curtain.visible


func open_character(character: String) -> void:
	if can_open_character(character) and character in SocialCharacters.known_characters(PlayerState.park_meeting_seen):
		SceneFade.play_action(show_social.bind(character))


func show_social(character: String) -> void:
	social_overlay = SOCIAL_SCENE.instantiate() as Social
	social_overlay.selected_character = character
	add_child(social_overlay)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(social_overlay):
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SceneFade.play_action(queue_free, -1.0)
