extends "res://scripts/map_destination.gd"

const FINAL_PROMISE_SCENE := preload("res://scenes/yue_final_promise.tscn")
const SHIRAKAWA_FIRST_STORY := preload("res://scenes/shirakawa_first_story.tscn")
const SHIRAKAWA_PUPPY := preload("res://scenes/shirakawa_puppy.tscn")
const SHIRAKAWA_OSMANTHUS := preload("res://scenes/shirakawa_osmanthus.tscn")
const SHIRAKAWA_CONFESSION := preload("res://scenes/shirakawa_confession.tscn")
const SHIRAKAWA_SNOW := preload("res://scenes/shirakawa_snow.tscn")
const CardCatalog := preload("res://scripts/card_catalog.gd")
const FUSHIMI_STORIES := {
	SocialCharacters.FushimiChapter.PEN: preload("res://scenes/fushimi_pen_story.tscn"),
	SocialCharacters.FushimiChapter.TUTORING: preload("res://scenes/fushimi_tutoring.tscn"),
	SocialCharacters.FushimiChapter.BOOKSHOP: preload("res://scenes/fushimi_bookshop.tscn"),
	SocialCharacters.FushimiChapter.CONFESSION: preload("res://scenes/fushimi_confession.tscn"),
	SocialCharacters.FushimiChapter.FINAL_PROMISE: preload("res://scenes/fushimi_final_promise.tscn"),
}


func open_character(character: String) -> void:
	if not PlayerState.has_character_story(character, scene_file_path):
		super.open_character(character)
		return
	if not can_open_character(character):
		return
	if character == SocialCharacters.FUSHIMI:
		var chapter := PlayerState.fushimi_story_chapter()
		if chapter == SocialCharacters.FushimiChapter.PEN and PlayerState.fushimi_pen_seen:
			SceneFade.play_action(show_fushimi_card_offer.bind(chapter))
			return
		if chapter == SocialCharacters.FushimiChapter.CONFESSION:
			request_confession_confirmation(SocialCharacters.FUSHIMI, confirm_fushimi_confession)
		else:
			play_fushimi_story(chapter)
	elif character == SocialCharacters.SHIRAKAWA:
		if PlayerState.shirakawa_snow_available():
			play_shirakawa_story(SHIRAKAWA_SNOW, 4, PlayerState.finish_shirakawa_snow)
		elif PlayerState.shirakawa_confession_available():
			request_confession_confirmation(SocialCharacters.SHIRAKAWA, confirm_shirakawa_confession)
		elif PlayerState.shirakawa_third_story_available():
			play_shirakawa_story(SHIRAKAWA_OSMANTHUS, 2, PlayerState.finish_shirakawa_third_story)
		elif PlayerState.shirakawa_second_story_available():
			play_shirakawa_story(SHIRAKAWA_PUPPY, 1, PlayerState.finish_shirakawa_second_story)
		else:
			play_shirakawa_story(SHIRAKAWA_FIRST_STORY, 0, PlayerState.finish_shirakawa_first_story)
	else:
		SceneFade.play_action(show_story.bind(FINAL_PROMISE_SCENE, PlayerState.yue_story_chapter()))


func confirm_shirakawa_confession(accepted: bool) -> void:
	if accepted and PlayerState.shirakawa_confession_available():
		play_shirakawa_story(SHIRAKAWA_CONFESSION, 3, PlayerState.finish_shirakawa_confession)


func play_shirakawa_story(scene: PackedScene, chapter: int, complete: Callable) -> void:
	SceneFade.play_action(show_dialogue.bind(scene, show_shirakawa_card_offer.bind(chapter, complete)))


func show_shirakawa_card_offer(chapter: int, complete: Callable) -> void:
	var card_id := CardCatalog.shirakawa_story_card(chapter)
	offer_story_card(SocialCharacters.SHIRAKAWA, card_id, complete_shirakawa_chapter.bind(card_id, complete))


func complete_shirakawa_chapter(add_to_deck: bool, card_id: int, complete: Callable) -> void:
	if add_to_deck:
		PlayerState.add_story_card(card_id)
	complete.call()


func confirm_fushimi_confession(accepted: bool) -> void:
	if accepted and PlayerState.fushimi_story_chapter() == SocialCharacters.FushimiChapter.CONFESSION:
		play_fushimi_story(SocialCharacters.FushimiChapter.CONFESSION)


func play_fushimi_story(chapter: SocialCharacters.FushimiChapter) -> void:
	var scene: PackedScene = FUSHIMI_STORIES[chapter]
	SceneFade.play_action(show_dialogue.bind(scene, show_fushimi_card_offer.bind(chapter)))


func show_fushimi_card_offer(chapter: SocialCharacters.FushimiChapter) -> void:
	offer_story_card(SocialCharacters.FUSHIMI, CardCatalog.fushimi_story_card(chapter), complete_fushimi_chapter.bind(chapter))


func complete_fushimi_chapter(add_to_deck: bool, chapter: SocialCharacters.FushimiChapter) -> void:
	PlayerState.finish_fushimi_story(chapter, add_to_deck)
