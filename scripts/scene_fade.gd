extends CanvasLayer

const PAPER_SWEEP := preload("res://shaders/scene_paper_sweep.gdshader")
const ROUND_INTRO := preload("res://scenes/round_intro.tscn")
const RoundIntro := preload("res://scripts/round_intro.gd")
const ROUND_EVENT := preload("res://scenes/round_event.tscn")
const RoundEvent := preload("res://scripts/round_event.gd")
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const StoryDialogue := preload("res://scripts/story_dialogue.gd")
const SCHOOL_INTRO := preload("res://scenes/school_intro.tscn")
const MIDDLE_SCHOOL_INTRO := preload("res://scenes/middle_school_intro.tscn")
const HIGH_SCHOOL_INTRO := preload("res://scenes/high_school_intro.tscn")
const STORY_PREVIEW_MENU_SCENE := preload("res://scenes/story_preview_menu.tscn")
const StoryPreviewMenu := preload("res://scripts/story_preview_menu.gd")
const BEDROOM_SCENE := "res://scenes/bedroom.tscn"
const DRAFT_SCENE := "res://scenes/deck_draft.tscn"
const BATTLE_TUTORIAL_SCENE := "res://scenes/battle_tutorial.tscn"
const FINAL_EXAM_ENDING_SCENE := "res://scenes/final_exam_ending.tscn"
const COVER_TIME := 0.42
const REVEAL_TIME := 0.48
const ROUND_INTRO_FADE_TIME := 0.28
const ROUND_INTRO_HOLD_TIME := 1.8

var curtain := ColorRect.new()
var transition_player := AudioStreamPlayer.new()
var paper_material := ShaderMaterial.new()
var event_panel: RoundEvent
var school_intro_panel: StoryDialogue
var story_preview_menu: StoryPreviewMenu

func _ready() -> void:
	layer = 100
	preload("res://audio/sfx/sound_library.gd").configure(transition_player, "transition")
	add_child(transition_player)
	paper_material.shader = PAPER_SWEEP
	curtain.material = paper_material
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.hide()
	add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_to(scene_path: String, direction: float = 1.0, round_number: int = 0, with_sound: bool = true) -> void:
	if curtain.visible:
		return
	if direction > 0.0 and with_sound:
		play_transition_sound()
	paper_material.set_shader_parameter("direction", direction)
	set_sweep_progress(0.0)
	curtain.show()
	await move_paper(0.0, 0.5, COVER_TIME, Tween.EASE_OUT)

	var tree := get_tree()
	var result := tree.change_scene_to_file(scene_path)
	if result == OK:
		await tree.scene_changed
	else:
		push_error("Could not open %s: %s" % [scene_path, error_string(result)])

	if result == OK and round_number > 0:
		await show_round_intro(round_number)
	else:
		await move_paper(0.5, 1.0, REVEAL_TIME, Tween.EASE_IN_OUT)
	if result == OK:
		if scene_path == BEDROOM_SCENE:
			await show_school_opening()
		if round_number > 0:
			await show_round_event()
	curtain.hide()

func advance_to_next_round() -> void:
	if curtain.visible or PlayerState.round_number >= RoundCalendar.FINAL_EXAM_ROUND:
		return
	PlayerState.advance_round()
	PlayerState.apply_next_round_energy_bonus()
	change_to(BEDROOM_SCENE, -1.0, PlayerState.round_number)

func starter_deck_entry_scene() -> String:
	return DRAFT_SCENE if PlayerState.battle_tutorial_seen else BATTLE_TUTORIAL_SCENE

func show_school_opening() -> void:
	var current_round := PlayerState.round_number
	if RoundCalendar.age(current_round) == RoundCalendar.SCHOOL_AGE and not PlayerState.school_intro_seen:
		await show_school_intro(SCHOOL_INTRO)
		PlayerState.school_intro_seen = true
	elif RoundCalendar.is_middle_school_start(current_round) and not PlayerState.middle_school_intro_seen:
		await show_school_intro(MIDDLE_SCHOOL_INTRO)
		PlayerState.middle_school_intro_seen = true
	elif RoundCalendar.is_high_school_start(current_round) and not PlayerState.high_school_intro_seen:
		await show_school_intro(HIGH_SCHOOL_INTRO)
		PlayerState.high_school_intro_seen = true

func show_school_intro(scene: PackedScene) -> void:
	school_intro_panel = scene.instantiate() as StoryDialogue
	add_child(school_intro_panel)
	await school_intro_panel.completed
	school_intro_panel.hide()
	school_intro_panel.queue_free()
	school_intro_panel = null

func show_round_intro(round_number: int) -> void:
	var intro := ROUND_INTRO.instantiate() as RoundIntro
	intro.modulate.a = 0.0
	add_child(intro)
	intro.show_round(round_number)

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(intro, "modulate:a", 1.0, ROUND_INTRO_FADE_TIME)
	tween.tween_interval(ROUND_INTRO_HOLD_TIME)
	tween.tween_property(intro, "modulate:a", 0.0, REVEAL_TIME)
	tween.parallel().tween_method(set_sweep_progress, 0.5, 1.0, REVEAL_TIME)
	await tween.finished
	intro.queue_free()

func show_round_event() -> void:
	var event_id := PlayerState.roll_round_event()
	if event_id.is_empty():
		return
	event_panel = ROUND_EVENT.instantiate() as RoundEvent
	add_child(event_panel)
	event_panel.show_event(event_id)
	await event_panel.completed
	event_panel.hide()
	event_panel.queue_free()
	event_panel = null

func play_action(action: Callable, direction: float = 1.0, with_sound: bool = true) -> void:
	if curtain.visible:
		return
	if direction > 0.0 and with_sound:
		play_transition_sound()
	paper_material.set_shader_parameter("direction", direction)
	set_sweep_progress(0.0)
	curtain.show()
	await move_paper(0.0, 0.5, COVER_TIME, Tween.EASE_OUT)
	action.call()
	await get_tree().process_frame
	await move_paper(0.5, 1.0, REVEAL_TIME, Tween.EASE_IN_OUT)
	curtain.hide()

func play_transition_sound() -> void:
	transition_player.play()

func move_paper(from: float, to: float, duration: float, easing: Tween.EaseType) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	tween.tween_method(set_sweep_progress, from, to, duration)
	await tween.finished

func set_sweep_progress(value: float) -> void:
	paper_material.set_shader_parameter("progress", value)

func open_story_preview_menu() -> void:
	var previous_focus := get_viewport().gui_get_focus_owner()
	story_preview_menu = STORY_PREVIEW_MENU_SCENE.instantiate() as StoryPreviewMenu
	story_preview_menu.closed.connect(close_story_preview_menu.bind(previous_focus), CONNECT_ONE_SHOT)
	get_tree().paused = true
	add_child(story_preview_menu)

func close_story_preview_menu(previous_focus: Control) -> void:
	story_preview_menu.hide()
	story_preview_menu.queue_free()
	story_preview_menu = null
	get_tree().paused = false
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var scene := get_tree().current_scene
		if scene != null and scene.scene_file_path not in ["res://scenes/card.tscn", BATTLE_TUTORIAL_SCENE]:
			get_viewport().set_input_as_handled()
			send_escape.call_deferred()
			return
	if SaveManager.debug_mode_enabled and not curtain.visible and not is_instance_valid(story_preview_menu) and not get_viewport().gui_get_focus_owner() is LineEdit and event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_I:
		get_viewport().set_input_as_handled()
		open_story_preview_menu()
		return
	var showing_cutscene := is_instance_valid(school_intro_panel) or is_instance_valid(event_panel)
	if curtain.visible and (not showing_cutscene or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()


func send_escape() -> void:
	for pressed in [true, false]:
		var escape_event := InputEventKey.new()
		escape_event.keycode = KEY_ESCAPE
		escape_event.pressed = pressed
		Input.parse_input_event(escape_event)
