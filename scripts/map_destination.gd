extends ColorRect

const SocialCharacters := preload("res://scripts/social_characters.gd")
const CharacterBadge := preload("res://scripts/character_badge.gd")
const SOCIAL_SCENE := preload("res://scenes/onsite_social.tscn")
const Social := preload("res://scripts/social.gd")
const StoryDialogue := preload("res://scripts/story_dialogue.gd")
const STORY_CARD_OFFER_SCENE := preload("res://scenes/story_card_offer.tscn")
const StoryCardOffer := preload("res://scripts/story_card_offer.gd")

@onready var visitors: HBoxContainer = $Visitors

var visitor_ids: Array[String] = []
var visitor_stories: Array[String] = []
var social_overlay: Social
var story: StoryDialogue
var story_card_offer: StoryCardOffer


func _ready() -> void:
	PlayerState.changed.connect(refresh_visitors)
	refresh_visitors()


func refresh_visitors() -> void:
	var here: Array[String] = []
	var stories: Array[String] = []
	var locations := PlayerState.social_locations()
	for character: String in locations:
		if locations[character] == scene_file_path:
			here.append(character)
			if PlayerState.has_character_story(character, scene_file_path):
				stories.append(character)
	if here == visitor_ids and stories == visitor_stories:
		return
	visitor_ids = here
	visitor_stories = stories
	visitors.offset_left = -36.0 - here.size() * 76.0 - maxi(0, here.size() - 1) * 10.0
	for child in visitors.get_children():
		visitors.remove_child(child)
		child.queue_free()
	for character in visitor_ids:
		var badge := CharacterBadge.new()
		badge.configure(SocialCharacters.avatar(character), character, 76.0, character in visitor_stories)
		badge.pressed.connect(open_character.bind(character))
		visitors.add_child(badge)


func can_open_character(character: String) -> bool:
	return character in visitor_ids and not is_instance_valid(social_overlay) and not is_instance_valid(story) and not is_instance_valid(story_card_offer) and not SceneFade.curtain.visible


func open_character(character: String) -> void:
	if can_open_character(character) and character in PlayerState.known_social_characters():
		SceneFade.play_action(show_social.bind(character))


func show_social(character: String) -> void:
	social_overlay = SOCIAL_SCENE.instantiate() as Social
	social_overlay.selected_character = character
	add_child(social_overlay)


func show_story(scene: PackedScene, chapter: SocialCharacters.YueChapter) -> void:
	show_dialogue(scene, show_story_card_offer.bind(chapter))


func show_dialogue(scene: PackedScene, on_complete: Callable) -> void:
	story = scene.instantiate() as StoryDialogue
	story.completed.connect(finish_dialogue.bind(on_complete), CONNECT_ONE_SHOT)
	add_child(story)


func finish_dialogue(on_complete: Callable) -> void:
	story.hide()
	story.queue_free()
	on_complete.call()


func show_story_card_offer(chapter: SocialCharacters.YueChapter) -> void:
	var card_id := PlayerState.yue_story_card_offer(chapter)
	offer_story_card(SocialCharacters.YUE, card_id, complete_yue_chapter.bind(chapter))


func complete_yue_chapter(add_to_deck: bool, chapter: SocialCharacters.YueChapter) -> void:
	PlayerState.finish_yue_story(chapter, add_to_deck)


func request_confession_confirmation(character: String, on_decide: Callable) -> void:
	story_card_offer = STORY_CARD_OFFER_SCENE.instantiate() as StoryCardOffer
	story_card_offer.decided.connect(finish_card_offer.bind(on_decide), CONNECT_ONE_SHOT)
	add_child(story_card_offer)
	story_card_offer.show_confession_confirmation(character)


func offer_story_card(character: String, card_id: int, on_decide: Callable) -> void:
	if card_id < 0:
		on_decide.call(false)
		return
	story_card_offer = STORY_CARD_OFFER_SCENE.instantiate() as StoryCardOffer
	story_card_offer.decided.connect(finish_card_offer.bind(on_decide), CONNECT_ONE_SHOT)
	add_child(story_card_offer)
	story_card_offer.show_offer(character, card_id)


func finish_card_offer(add_to_deck: bool, on_decide: Callable) -> void:
	story_card_offer.hide()
	story_card_offer.queue_free()
	on_decide.call(add_to_deck)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(story) or is_instance_valid(story_card_offer):
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(social_overlay):
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SceneFade.play_action(queue_free, -1.0)
