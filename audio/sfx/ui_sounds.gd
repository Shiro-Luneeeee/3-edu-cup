extends Node

var click_player: AudioStreamPlayer
var phone_player: AudioStreamPlayer
var game_selection_player: AudioStreamPlayer
var study_player: AudioStreamPlayer
var study_subject_player: AudioStreamPlayer
var study_action_player: AudioStreamPlayer
var soft_click_player: AudioStreamPlayer
var victory_player: AudioStreamPlayer
var card_upgrade_player: AudioStreamPlayer
var card_upgrade_success_player: AudioStreamPlayer
var story_card_reward_player: AudioStreamPlayer
var match_start_player: AudioStreamPlayer
var purchase_player: AudioStreamPlayer


func _ready() -> void:
	click_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(click_player, "ui_click")
	add_child(click_player)
	phone_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(phone_player, "phone")
	add_child(phone_player)
	game_selection_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(game_selection_player, "game_selection")
	add_child(game_selection_player)
	study_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(study_player, "study")
	add_child(study_player)
	study_subject_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(study_subject_player, "study_subject")
	add_child(study_subject_player)
	study_action_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(study_action_player, "study_action")
	add_child(study_action_player)
	soft_click_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(soft_click_player, "soft_click")
	add_child(soft_click_player)
	victory_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(victory_player, "victory")
	add_child(victory_player)
	card_upgrade_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(card_upgrade_player, "open_card_upgrade")
	add_child(card_upgrade_player)
	card_upgrade_success_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(card_upgrade_success_player, "card_upgrade_success")
	add_child(card_upgrade_success_player)
	story_card_reward_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(story_card_reward_player, "story_card_reward")
	add_child(story_card_reward_player)
	match_start_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(match_start_player, "match_start")
	add_child(match_start_player)
	purchase_player = AudioStreamPlayer.new()
	preload("res://audio/sfx/sound_library.gd").configure(purchase_player, "purchase")
	add_child(purchase_player)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var hovered := get_viewport().gui_get_hovered_control()
		while hovered != null:
			if hovered is BaseButton:
				if not hovered.disabled:
					play_button_sound(hovered)
				return
			if hovered is ItemList and hovered.is_in_group("soft_selection"):
				return
			if hovered.is_in_group("map_location_surface"):
				return
			if hovered.is_in_group("soft_selection"):
				play_soft_click()
				return
			if hovered is HSlider or hovered.mouse_default_cursor_shape == Control.CURSOR_POINTING_HAND:
				play_click()
				return
			hovered = hovered.get_parent() as Control
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		var focused := get_viewport().gui_get_focus_owner()
		if focused is BaseButton and not focused.disabled:
			play_button_sound(focused)


func play_button_sound(button: BaseButton) -> void:
	if button.is_in_group("silent_story_advance") or button.is_in_group("map_location_surface") or button.is_in_group("game_play_button") or button.is_in_group("silent_match_start") or button.is_in_group("purchase_button") or button.is_in_group("card_upgrade_apply"):
		return
	if button.is_in_group("phone_view_button"):
		phone_player.play()
	elif button.is_in_group("game_selection_button"):
		game_selection_player.play()
	elif button.is_in_group("study_button"):
		study_player.play()
	elif button.is_in_group("card_upgrade_button"):
		card_upgrade_player.play()
	elif button.is_in_group("match_start_entry_button"):
		match_start_player.play()
	elif button.is_in_group("study_subject_button"):
		study_subject_player.play()
	elif button.is_in_group("study_action_button"):
		study_action_player.play()
	elif button.is_in_group("soft_selection"):
		play_soft_click()
	else:
		play_click()


func play_soft_click() -> void:
	soft_click_player.play()


func play_victory() -> void:
	victory_player.play()


func play_match_start() -> void:
	match_start_player.play()


func play_card_upgrade_success() -> void:
	card_upgrade_success_player.play()


func play_story_card_reward() -> void:
	story_card_reward_player.play()


func play_purchase() -> float:
	purchase_player.play()
	return purchase_player.stream.get_length()


func play_click() -> void:
	click_player.play()
