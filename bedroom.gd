extends Control

const IMAGE_SIZE := Vector2(1672, 941)
const BEDROOM_SCENE := "res://bedroom.tscn"
const CLOCK_RECT := Rect2(1000, 300, 175, 230)
const PHONE_RECT := Rect2(1339, 589, 274, 178)
const BOOKSHELF_RECT := Rect2(0, 162, 277, 401)
const GAMEPAD_RECT := Rect2(80, 590, 360, 225)
const NOTEBOOK_RECT := Rect2(666, 565, 432, 300)
const PREPARATION_SCENE := "res://lobby.tscn"
const GAME_SELECTION_SCENE := "res://game_selection.tscn"
const SHOP_SCENE := "res://shop.tscn"
const MAP_SCENE := preload("res://map.tscn")
const STUDY_SCENE := preload("res://study.tscn")
const GALLERY_SCENE: PackedScene = preload("res://gallery.tscn")
const UPGRADE_SCENE := preload("res://card_upgrade.tscn")
const SOCIAL_SCENE := preload("res://social.tscn")
const TUTORIAL_SCENE := preload("res://bedroom_tutorial.tscn")
const BEDROOM_PLAYLIST := [
	preload("res://audio/music/Mateus Asato - Kawaii.mp3"),
	preload("res://audio/music/Mateus Asato - MA.mp3"),
	preload("res://audio/music/birth_cryin.mp3"),
	preload("res://audio/music/Mateus Asato - too nerdy for pop, too pop for nerds.mp3"),
]
const RoundCalendar := preload("res://round_calendar.gd")
const ROUND_BOARD_WIDTH := 136.0
@export_range(0, 100, 1) var intelligence := 0
@export_range(0, 100, 1) var emotional_intelligence := 0
@export_range(0, 100, 1) var physical_strength := 0
@export_range(1, 1000, 1) var max_energy := 20

@onready var bedroom_music: AudioStreamPlayer = $BedroomMusic
@onready var exit_button: TextureButton = $ExitButton
@onready var clock_button: Button = $ClockButton
@onready var clock_highlight: Polygon2D = $ClockButton/ClockHighlight
@onready var phone_button: Button = $PhoneButton
@onready var phone_highlight: Polygon2D = $PhoneButton/PhoneHighlight
@onready var bookshelf_button: Button = $BookshelfButton
@onready var bookshelf_highlight: Polygon2D = $BookshelfButton/BookshelfHighlight
@onready var gamepad_button: Button = $GamepadButton
@onready var gamepad_highlight: Polygon2D = $GamepadButton/GamepadHighlight
@onready var notebook_button: Button = $NotebookButton
@onready var notebook_highlight: Polygon2D = $NotebookButton/NotebookHighlight
@onready var round_board: TextureRect = $RoundBoard
@onready var round_label: Label = $RoundBoard/RoundLabel
@onready var phone_overlay: ColorRect = $PhoneOverlay
@onready var phone_image: TextureRect = $PhoneOverlay/PhoneImage
@onready var shop_app: TextureButton = $PhoneOverlay/PhoneImage/SecondAppRow/Shop
@onready var power_app: TextureButton = $PhoneOverlay/PhoneImage/Dock/Boot
@onready var gallery_app: TextureButton = $PhoneOverlay/PhoneImage/AppRow/Gallery
@onready var map_app: TextureButton = $PhoneOverlay/PhoneImage/AppRow/Map
@onready var social_app: TextureButton = $PhoneOverlay/PhoneImage/AppRow/Chat

var highlight_tweens: Dictionary[Polygon2D, Tween] = {}
var gallery_overlay: Control
var study_overlay: Control
var map_overlay: Control
var upgrade_overlay: Control
var social_overlay: Control
var tutorial_overlay: Control
func _ready() -> void:
	bedroom_music = SaveManager.use_scene_playlist(BEDROOM_SCENE, bedroom_music, BEDROOM_PLAYLIST)
	PlayerState.initialize(intelligence, emotional_intelligence, physical_strength, max_energy)
	PlayerState.changed.connect(update_player_display)
	resized.connect(update_layout)
	connect_highlight(clock_button, clock_highlight)
	connect_highlight(phone_button, phone_highlight)
	connect_highlight(bookshelf_button, bookshelf_highlight)
	connect_highlight(gamepad_button, gamepad_highlight)
	connect_highlight(notebook_button, notebook_highlight)
	clock_button.pressed.connect(use_clock)
	gamepad_button.pressed.connect(open_game_selection)
	notebook_button.pressed.connect(open_card_upgrades)
	phone_button.pressed.connect(phone_overlay.show)
	bookshelf_button.pressed.connect(open_study)
	shop_app.pressed.connect(open_shop)
	power_app.pressed.connect(phone_overlay.hide)
	gallery_app.pressed.connect(open_gallery)
	map_app.pressed.connect(open_map)
	social_app.pressed.connect(open_social)
	exit_button.pressed.connect(SaveManager.open_save_page)
	phone_overlay.gui_input.connect(on_phone_overlay_input)
	update_layout()
	if PlayerState.bedroom_tutorial_pending and not PlayerState.bedroom_tutorial_seen:
		call_deferred("show_tutorial_after_intro")

func _exit_tree() -> void:
	SaveManager.release_scene_music(BEDROOM_SCENE)


func show_tutorial_after_intro() -> void:
	while is_inside_tree() and SceneFade.curtain.visible:
		await get_tree().process_frame
	if not is_inside_tree() or not PlayerState.bedroom_tutorial_pending or PlayerState.bedroom_tutorial_seen:
		return
	tutorial_overlay = TUTORIAL_SCENE.instantiate() as Control
	tutorial_overlay.set("bedroom", self)
	tutorial_overlay.connect("finished", finish_tutorial, CONNECT_ONE_SHOT)
	add_child(tutorial_overlay)


func finish_tutorial() -> void:
	PlayerState.bedroom_tutorial_pending = false
	PlayerState.bedroom_tutorial_seen = true
	tutorial_overlay = null

func set_energy(value: int) -> void:
	PlayerState.set_energy(value)

func set_max_energy(value: int, refill: bool = false) -> void:
	PlayerState.set_max_energy(value, refill)

func update_player_display() -> void:
	var current_round := PlayerState.round_number
	round_label.text = "%d 岁" % RoundCalendar.age(current_round)
	round_board.tooltip_text = "第 %d 轮  ·  %s" % [current_round, RoundCalendar.season_and_grade(current_round)]
	clock_button.tooltip_text = "开始牌局" if RoundCalendar.has_card_match(current_round) else "进入下一轮"
	clock_button.disabled = PlayerState.final_exam_started
	if RoundCalendar.is_final_exam(current_round):
		clock_button.tooltip_text = "高考已结束" if PlayerState.final_exam_started else "参加高考"
	social_app.disabled = false
	social_app.modulate.a = 1.0
	social_app.tooltip_text = "社交"

func open_shop() -> void:
	SceneFade.change_to(SHOP_SCENE)


func open_game_selection() -> void:
	if SceneFade.curtain.visible:
		return
	SaveManager.keep_scene_music_on_exit()
	SceneFade.change_to(GAME_SELECTION_SCENE)


func use_clock() -> void:
	if PlayerState.final_exam_started:
		return
	if RoundCalendar.has_card_match(PlayerState.round_number):
		SceneFade.change_to(PREPARATION_SCENE)
	else:
		SceneFade.advance_to_next_round()

func open_map() -> void:
	if not is_instance_valid(map_overlay):
		SceneFade.play_action(show_map_overlay)

func show_map_overlay() -> void:
	phone_overlay.hide()
	map_overlay = MAP_SCENE.instantiate() as Control
	add_child(map_overlay)


func open_social() -> void:
	if not is_instance_valid(social_overlay):
		SceneFade.play_action(show_social)


func show_social() -> void:
	social_overlay = SOCIAL_SCENE.instantiate() as Control
	add_child(social_overlay)

func open_study() -> void:
	if not is_instance_valid(study_overlay):
		SceneFade.play_action(show_study_overlay)

func show_study_overlay() -> void:
	study_overlay = STUDY_SCENE.instantiate() as Control
	add_child(study_overlay)

func open_card_upgrades() -> void:
	if not is_instance_valid(upgrade_overlay):
		SceneFade.play_action(show_card_upgrades)

func show_card_upgrades() -> void:
	upgrade_overlay = UPGRADE_SCENE.instantiate() as Control
	add_child(upgrade_overlay)

func open_gallery() -> void:
	if is_instance_valid(gallery_overlay):
		return
	SceneFade.play_action(show_gallery_overlay)

func show_gallery_overlay() -> void:
	phone_overlay.hide()
	bedroom_music.stream_paused = true
	gallery_overlay = GALLERY_SCENE.instantiate() as Control
	gallery_overlay.set_return_to_bedroom()
	add_child(gallery_overlay)
	gallery_overlay.tree_exited.connect(resume_music_after_gallery)

func resume_music_after_gallery() -> void:
	gallery_overlay = null
	bedroom_music.stream_paused = false

func update_layout() -> void:
	var image_scale := minf(size.x / IMAGE_SIZE.x, size.y / IMAGE_SIZE.y)
	var image_origin := (size - IMAGE_SIZE * image_scale) / 2.0
	var round_board_scale := ROUND_BOARD_WIDTH * image_scale / round_board.texture.get_width()
	round_board.size = round_board.texture.get_size() * round_board_scale
	round_board.position = image_origin + Vector2(IMAGE_SIZE.x - ROUND_BOARD_WIDTH - 38.0, 24.0) * image_scale
	round_label.add_theme_font_size_override("font_size", maxi(1, roundi(39.0 * image_scale)))
	update_player_display()
	place_hotspot(clock_button, clock_highlight, CLOCK_RECT, image_origin, image_scale)
	place_hotspot(phone_button, phone_highlight, PHONE_RECT, image_origin, image_scale)
	place_hotspot(bookshelf_button, bookshelf_highlight, BOOKSHELF_RECT, image_origin, image_scale)
	place_hotspot(gamepad_button, gamepad_highlight, GAMEPAD_RECT, image_origin, image_scale)
	place_hotspot(notebook_button, notebook_highlight, NOTEBOOK_RECT, image_origin, image_scale)

	var phone_size := phone_image.texture.get_size()
	var phone_scale := minf(size.x / phone_size.x, size.y / phone_size.y) * 0.88
	phone_image.size = phone_size * phone_scale
	phone_image.position = (size - phone_image.size) / 2.0

func place_hotspot(button: Button, highlight: Polygon2D, rect: Rect2, origin: Vector2, image_scale: float) -> void:
	button.position = origin + rect.position * image_scale
	button.size = rect.size * image_scale
	highlight.scale = Vector2.ONE * image_scale

func connect_highlight(button: Button, highlight: Polygon2D) -> void:
	button.mouse_entered.connect(set_highlight.bind(highlight, true))
	button.mouse_exited.connect(set_highlight.bind(highlight, false))

func set_highlight(highlight: Polygon2D, hovered: bool) -> void:
	if highlight_tweens.has(highlight):
		highlight_tweens[highlight].kill()
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	highlight_tweens[highlight] = tween
	tween.tween_property(highlight, "modulate:a", 1.0 if hovered else 0.0, 0.18)

func on_phone_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		phone_overlay.hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(tutorial_overlay):
		return
	if is_instance_valid(social_overlay):
		return
	if phone_overlay.visible and event.is_action_pressed("ui_cancel"):
		phone_overlay.hide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SaveManager.open_save_page()
