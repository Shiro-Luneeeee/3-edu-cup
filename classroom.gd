extends "res://map_destination.gd"

const FINAL_PROMISE_SCENE := preload("res://yue_final_promise.tscn")
const CardCatalog := preload("res://card_catalog.gd")
const FUSHIMI_STORIES := {
	SocialCharacters.FushimiChapter.PEN: preload("res://fushimi_pen_story.tscn"),
	SocialCharacters.FushimiChapter.TUTORING: preload("res://fushimi_tutoring.tscn"),
	SocialCharacters.FushimiChapter.BOOKSHOP: preload("res://fushimi_bookshop.tscn"),
	SocialCharacters.FushimiChapter.CONFESSION: preload("res://fushimi_confession.tscn"),
	SocialCharacters.FushimiChapter.FINAL_PROMISE: preload("res://fushimi_final_promise.tscn"),
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
	else:
		SceneFade.play_action(show_story.bind(FINAL_PROMISE_SCENE, PlayerState.yue_story_chapter()))


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
