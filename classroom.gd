extends "res://map_destination.gd"

const FINAL_PROMISE_SCENE := preload("res://yue_final_promise.tscn")
const FUSHIMI_PEN_SCENE := preload("res://fushimi_pen_story.tscn")


func open_character(character: String) -> void:
	if not PlayerState.has_character_story(character, scene_file_path):
		super.open_character(character)
		return
	if not can_open_character(character):
		return
	if character == SocialCharacters.FUSHIMI:
		SceneFade.play_action(show_dialogue.bind(FUSHIMI_PEN_SCENE, PlayerState.finish_fushimi_pen_story))
	else:
		SceneFade.play_action(show_story.bind(FINAL_PROMISE_SCENE, PlayerState.yue_story_chapter()))
