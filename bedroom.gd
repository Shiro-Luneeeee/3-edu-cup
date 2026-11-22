extends Control

const IMAGE_SIZE := Vector2(1672, 941)
const BEDROOM_SCENE := "res://bedroom.tscn"
const CLOCK_RECT := Rect2(1000, 300, 175, 230)
const PHONE_RECT := Rect2(1339, 589, 274, 178)
const BOOKSHELF_RECT := Rect2(0, 162, 277, 401)
const GAMEPAD_RECT := Rect2(80, 590, 360, 225)
const PREPARATION_SCENE := "res://lobby.tscn"
const GAME_SELECTION_SCENE := "res://game_selection.tscn"
const SHOP_SCENE := "res://shop.tscn"
const MAP_SCENE := preload("res://map.tscn")
const STUDY_SCENE := preload("res://study.tscn")
const GALLERY_SCENE: PackedScene = preload("res://gallery.tscn")
const POINT_BOARD_TEXTURE: Texture2D = preload("res://images/ui/point_board.png")
const HERO_PORTRAIT_TEXTURE: Texture2D = preload("res://images/character/ShiroLune_cutout.png")
const POINT_BOARD_SIZE := Vector2(580.0, 290.0)
# Slot bounds in point_board.png, from top to bottom.
const STAT_TRACK_RECTS := [
	Vector4(869.0, 257.0, 562.0, 44.0),
	Vector4(870.0, 424.0, 561.0, 44.0),
	Vector4(871.0, 592.0, 561.0, 46.0),
]
const STAT_VALUE_FONT_SIZE := 23.0
const ROUND_BOARD_WIDTH := 136.0
const ENERGY_BAR_WIDTH := 430.0
const ENERGY_TRACK_IN_TEXTURE := Rect2(372.0, 328.0, 1552.0, 134.0)
const ENERGY_VALUE_FONT_SIZE_IN_TEXTURE := 116.0
const ENERGY_BAR_TEXTURE := preload("res://images/ui/energy_bar.png")
const ENERGY_FILL_SHADER := preload("res://energy_bar_fill.gdshader")

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
@onready var round_board: TextureRect = $RoundBoard
@onready var round_label: Label = $RoundBoard/RoundLabel
@onready var phone_overlay: ColorRect = $PhoneOverlay
@onready var phone_image: TextureRect = $PhoneOverlay/PhoneImage
@onready var shop_app: TextureButton = $PhoneOverlay/PhoneImage/SecondAppRow/Shop
@onready var power_app: TextureButton = $PhoneOverlay/PhoneImage/Dock/Boot
@onready var gallery_app: TextureButton = $PhoneOverlay/PhoneImage/AppRow/Gallery
@onready var map_app: TextureButton = $PhoneOverlay/PhoneImage/AppRow/Map

var highlight_tweens: Dictionary[Polygon2D, Tween] = {}
var gallery_overlay: Control
var study_overlay: Control
var map_overlay: Control
var point_board: TextureRect
var point_board_material: ShaderMaterial
var stat_labels: Array[Label] = []
var energy_bar: TextureRect
var energy_material: ShaderMaterial
var energy_label: Label

func _ready() -> void:
	bedroom_music = SaveManager.use_scene_music(BEDROOM_SCENE, bedroom_music)
	PlayerState.initialize(intelligence, emotional_intelligence, physical_strength, max_energy)
	create_point_board()
	create_energy_bar()
	PlayerState.changed.connect(update_player_display)
	resized.connect(update_layout)
	connect_highlight(clock_button, clock_highlight)
	connect_highlight(phone_button, phone_highlight)
	connect_highlight(bookshelf_button, bookshelf_highlight)
	connect_highlight(gamepad_button, gamepad_highlight)
	clock_button.pressed.connect(SceneFade.change_to.bind(PREPARATION_SCENE))
	gamepad_button.pressed.connect(SceneFade.change_to.bind(GAME_SELECTION_SCENE))
	phone_button.pressed.connect(phone_overlay.show)
	bookshelf_button.pressed.connect(open_study)
	shop_app.pressed.connect(open_shop)
	power_app.pressed.connect(phone_overlay.hide)
	gallery_app.pressed.connect(open_gallery)
	map_app.pressed.connect(open_map)
	exit_button.pressed.connect(SaveManager.open_save_page)
	$NextRoundButton.pressed.connect(func() -> void: SceneFade.play_action(PlayerState.advance_round))
	phone_overlay.gui_input.connect(on_phone_overlay_input)
	update_layout()


func _exit_tree() -> void:
	SaveManager.release_scene_music(BEDROOM_SCENE)

func create_energy_bar() -> void:
	energy_bar = TextureRect.new()
	energy_bar.name = "EnergyBar"
	energy_bar.texture = ENERGY_BAR_TEXTURE
	energy_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_bar.stretch_mode = TextureRect.STRETCH_SCALE
	energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	energy_material = ShaderMaterial.new()
	energy_material.shader = ENERGY_FILL_SHADER
	var track := ENERGY_TRACK_IN_TEXTURE
	energy_material.set_shader_parameter("track_rect", Vector4(track.position.x, track.position.y, track.size.x, track.size.y))
	energy_bar.material = energy_material
	add_child(energy_bar)
	move_child(energy_bar, point_board.get_index() + 1)

	energy_label = Label.new()
	energy_label.name = "EnergyValue"
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var value_font := FontVariation.new()
	value_font.base_font = preload("res://fonts/IndieFlower-Regular.ttf")
	value_font.variation_embolden = 0.6
	energy_label.add_theme_font_override("font", value_font)
	energy_label.add_theme_color_override("font_color", Color.WHITE)
	energy_label.add_theme_color_override("font_outline_color", Color("47345e"))
	energy_label.add_theme_constant_override("outline_size", 3)
	energy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar.add_child(energy_label)

func set_energy(value: int) -> void:
	PlayerState.set_energy(value)

func set_max_energy(value: int, refill: bool = false) -> void:
	PlayerState.set_max_energy(value, refill)

func update_player_display() -> void:
	round_label.text = "%d岁" % PlayerState.get_age_years()
	update_energy_display()
	update_point_board_values()

func update_energy_display() -> void:
	if energy_label == null:
		return
	var texture_scale := energy_bar.size.x / energy_bar.texture.get_width()
	var track := Rect2(ENERGY_TRACK_IN_TEXTURE.position * texture_scale, ENERGY_TRACK_IN_TEXTURE.size * texture_scale)
	var ratio := float(PlayerState.current_energy) / PlayerState.max_energy
	energy_material.set_shader_parameter("fill_ratio", ratio)
	energy_label.text = "%d/%d" % [PlayerState.current_energy, PlayerState.max_energy]
	energy_label.add_theme_font_size_override("font_size", maxi(1, roundi(ENERGY_VALUE_FONT_SIZE_IN_TEXTURE * texture_scale)))
	energy_label.size = track.size
	energy_label.position = track.get_center() - energy_label.size * 0.5

func create_point_board() -> void:
	point_board = TextureRect.new()
	point_board.name = "PointBoard"
	point_board.texture = POINT_BOARD_TEXTURE
	point_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	point_board.stretch_mode = TextureRect.STRETCH_SCALE
	point_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_board_material = ShaderMaterial.new()
	point_board_material.shader = ENERGY_FILL_SHADER
	point_board_material.set_shader_parameter("track_rect", STAT_TRACK_RECTS[0])
	point_board_material.set_shader_parameter("extra_track_rects", PackedVector4Array([STAT_TRACK_RECTS[1], STAT_TRACK_RECTS[2]]))
	point_board.material = point_board_material
	add_child(point_board)
	move_child(point_board, $Background.get_index() + 1)

	var portrait_clip := Control.new()
	portrait_clip.name = "HeroPortraitClip"
	portrait_clip.position = Vector2(34.0, 82.0)
	portrait_clip.size = Vector2(108.0, 108.0)
	portrait_clip.clip_contents = true
	portrait_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_board.add_child(portrait_clip)
	var portrait := TextureRect.new()
	portrait.name = "HeroPortrait"
	portrait.texture = HERO_PORTRAIT_TEXTURE
	portrait.position = Vector2(-3.0, -2.0)
	portrait.size = Vector2(114.0, 114.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_clip.add_child(portrait)

	for index in STAT_TRACK_RECTS.size():
		var value_label := Label.new()
		value_label.name = "StatValue%d" % index
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		value_label.add_theme_color_override("font_color", Color("594375"))
		value_label.add_theme_color_override("font_outline_color", Color("fff0cc"))
		value_label.add_theme_constant_override("outline_size", 2)
		value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		point_board.add_child(value_label)
		stat_labels.append(value_label)

func update_point_board_values() -> void:
	var values := [PlayerState.intelligence, PlayerState.emotional_intelligence, PlayerState.physical_strength]
	var fill_ratios := Vector3.ZERO
	for index in values.size():
		stat_labels[index].text = str(values[index])
		fill_ratios[index] = clampf(values[index] / 100.0, 0.0, 1.0)
	point_board_material.set_shader_parameter("fill_ratio", fill_ratios.x)
	point_board_material.set_shader_parameter("extra_fill_ratios", Vector2(fill_ratios.y, fill_ratios.z))

func open_shop() -> void:
	SceneFade.change_to(SHOP_SCENE)

func open_map() -> void:
	if not is_instance_valid(map_overlay):
		SceneFade.play_action(show_map_overlay)

func show_map_overlay() -> void:
	phone_overlay.hide()
	map_overlay = MAP_SCENE.instantiate() as Control
	add_child(map_overlay)

func open_study() -> void:
	if not is_instance_valid(study_overlay):
		SceneFade.play_action(show_study_overlay)

func show_study_overlay() -> void:
	study_overlay = STUDY_SCENE.instantiate() as Control
	add_child(study_overlay)

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
	if energy_bar != null:
		energy_bar.size = energy_bar.texture.get_size() * (ENERGY_BAR_WIDTH * image_scale / energy_bar.texture.get_width())
		energy_bar.position = Vector2((size.x - energy_bar.size.x) * 0.5, image_origin.y + 6.0 * image_scale)
	if point_board != null:
		point_board.position = image_origin + Vector2(12.0, 8.0) * image_scale
		point_board.size = POINT_BOARD_SIZE * image_scale
		var texture_scale_y := point_board.size.y / point_board.texture.get_height()
		var stat_font_size := maxi(1, roundi(STAT_VALUE_FONT_SIZE * image_scale))
		for index in stat_labels.size():
			var value_label := stat_labels[index]
			var track: Vector4 = STAT_TRACK_RECTS[index]
			var center_y := (track.y + track.w * 0.5) * texture_scale_y
			value_label.add_theme_font_size_override("font_size", stat_font_size)
			value_label.size = Vector2(60.0, 34.0) * image_scale
			value_label.position = Vector2(477.0 * image_scale, center_y - value_label.size.y * 0.5)
	var round_board_scale := ROUND_BOARD_WIDTH * image_scale / round_board.texture.get_width()
	round_board.size = round_board.texture.get_size() * round_board_scale
	round_board.position = image_origin + Vector2(IMAGE_SIZE.x - ROUND_BOARD_WIDTH - 38.0, 24.0) * image_scale
	round_label.add_theme_font_size_override("font_size", maxi(1, roundi(40.0 * image_scale)))
	update_player_display()
	place_hotspot(clock_button, clock_highlight, CLOCK_RECT, image_origin, image_scale)
	place_hotspot(phone_button, phone_highlight, PHONE_RECT, image_origin, image_scale)
	place_hotspot(bookshelf_button, bookshelf_highlight, BOOKSHELF_RECT, image_origin, image_scale)
	place_hotspot(gamepad_button, gamepad_highlight, GAMEPAD_RECT, image_origin, image_scale)

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
	if phone_overlay.visible and event.is_action_pressed("ui_cancel"):
		phone_overlay.hide()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SaveManager.open_save_page()
