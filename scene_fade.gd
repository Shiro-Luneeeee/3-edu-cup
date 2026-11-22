extends CanvasLayer

const PAPER_SWEEP := preload("res://scene_paper_sweep.gdshader")
const ROUND_INTRO := preload("res://round_intro.tscn")
const RoundIntro := preload("res://round_intro.gd")
const ROUND_EVENT := preload("res://round_event.tscn")
const RoundEvent := preload("res://round_event.gd")
const RoundCalendar := preload("res://round_calendar.gd")
const StoryDialogue := preload("res://story_dialogue.gd")
const SCHOOL_INTRO := preload("res://school_intro.tscn")
const GOLDFISH_SCENE := preload("res://yue_goldfish.tscn")
const FAREWELL_SCENE := preload("res://yue_farewell.tscn")
const STORY_CARD_OFFER_SCENE := preload("res://story_card_offer.tscn")
const StoryCardOffer := preload("res://story_card_offer.gd")
const SocialCharacters := preload("res://social_characters.gd")
const CardCatalog := preload("res://card_catalog.gd")
const BEDROOM_SCENE := "res://bedroom.tscn"
const COVER_TIME := 0.42
const REVEAL_TIME := 0.48
const ROUND_INTRO_FADE_TIME := 0.28
const ROUND_INTRO_HOLD_TIME := 1.8

var curtain := ColorRect.new()
var paper_material := ShaderMaterial.new()
var event_panel: RoundEvent
var school_intro_panel: StoryDialogue
var story_preview: StoryDialogue

func _ready() -> void:
	layer = 100
	paper_material.shader = PAPER_SWEEP
	curtain.material = paper_material
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.hide()
	add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_to(scene_path: String, direction: float = 1.0, round_number: int = 0) -> void:
	if curtain.visible:
		return
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
		if scene_path == BEDROOM_SCENE and RoundCalendar.age(PlayerState.round_number) == RoundCalendar.SCHOOL_AGE and not PlayerState.school_intro_seen:
			await show_school_intro()
		if round_number > 0:
			await show_round_event()
	curtain.hide()

func advance_to_next_round() -> void:
	if curtain.visible:
		return
	PlayerState.advance_round()
	PlayerState.apply_next_round_energy_bonus()
	change_to(BEDROOM_SCENE, -1.0, PlayerState.round_number)

func show_school_intro() -> void:
	school_intro_panel = SCHOOL_INTRO.instantiate() as StoryDialogue
	add_child(school_intro_panel)
	await school_intro_panel.completed
	PlayerState.school_intro_seen = true
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

func play_action(action: Callable, direction: float = 1.0) -> void:
	if curtain.visible:
		return
	paper_material.set_shader_parameter("direction", direction)
	set_sweep_progress(0.0)
	curtain.show()
	await move_paper(0.0, 0.5, COVER_TIME, Tween.EASE_OUT)
	action.call()
	await get_tree().process_frame
	await move_paper(0.5, 1.0, REVEAL_TIME, Tween.EASE_IN_OUT)
	curtain.hide()

func move_paper(from: float, to: float, duration: float, easing: Tween.EaseType) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	tween.tween_method(set_sweep_progress, from, to, duration)
	await tween.finished

func set_sweep_progress(value: float) -> void:
	paper_material.set_shader_parameter("progress", value)

func open_story_preview(chapter: SocialCharacters.YueChapter) -> void:
	var scene := GOLDFISH_SCENE if chapter == SocialCharacters.YueChapter.GOLDFISH else FAREWELL_SCENE
	story_preview = scene.instantiate() as StoryDialogue
	story_preview.preview_only = true
	story_preview.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	story_preview.completed.connect(show_preview_card_offer.bind(chapter), CONNECT_ONE_SHOT)
	story_preview.preview_cancelled.connect(close_story_preview, CONNECT_ONE_SHOT)
	get_tree().paused = true
	add_child(story_preview)

func show_preview_card_offer(chapter: SocialCharacters.YueChapter) -> void:
	var card_id := CardCatalog.yue_story_card(chapter)
	if card_id < 0:
		close_story_preview()
		return
	story_preview.dialogue_box.hide()
	var offer := STORY_CARD_OFFER_SCENE.instantiate() as StoryCardOffer
	offer.decided.connect(close_story_preview.unbind(1), CONNECT_ONE_SHOT)
	story_preview.add_child(offer)
	offer.show_offer(SocialCharacters.YUE, card_id, true)

func close_story_preview() -> void:
	story_preview.hide()
	story_preview.queue_free()
	story_preview = null
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and not curtain.visible and event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_I:
		get_viewport().set_input_as_handled()
		var chapter := SocialCharacters.YueChapter.GOLDFISH if event.shift_pressed else SocialCharacters.YueChapter.FAREWELL
		open_story_preview(chapter)
		return
	var showing_cutscene := is_instance_valid(school_intro_panel) or is_instance_valid(event_panel)
	if curtain.visible and (not showing_cutscene or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
