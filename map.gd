extends ColorRect

const MapLocation := preload("res://map_location.gd")
const SocialCharacters := preload("res://social_characters.gd")
const CharacterBadge := preload("res://character_badge.gd")
const MARKER_SIZE := 91.0
const MARKER_GAP := 10.0

@onready var artwork: Node2D = $Artwork
@onready var map_image: Sprite2D = $Artwork/MapImage
@onready var locations: Node2D = $Artwork/Locations
@onready var character_markers: Node2D = $Artwork/CharacterMarkers

var hovered_location: MapLocation
var hovered_character := ""
var pressed_location: MapLocation
var destination_overlay: Control
var opening_destination := false
var hover_card := Panel.new()
var hover_text := Label.new()
var last_character_locations: Dictionary[String, String] = {}
var last_story_characters: Array[String] = []


func _ready() -> void:
	for location: MapLocation in locations.get_children():
		location.configure(map_image.texture)
	var hint_style := StyleBoxFlat.new()
	hint_style.bg_color = Color(1, 0.963, 0.931, 0.97)
	hint_style.border_color = Color(0.86, 0.68, 0.75)
	hint_style.set_border_width_all(1)
	hint_style.set_corner_radius_all(17)
	hint_style.shadow_color = Color(0.25, 0.14, 0.32, 0.26)
	hint_style.shadow_size = 11
	hint_style.shadow_offset = Vector2(0, 5)
	hover_card.add_theme_stylebox_override("panel", hint_style)
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.visible = false
	add_child(hover_card)
	hover_card.add_child(hover_text)
	hover_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_text.add_theme_font_size_override("font_size", 19)
	hover_text.add_theme_color_override("font_color", Color("514d54"))
	PlayerState.changed.connect(refresh_character_markers)
	refresh_character_markers()
	resized.connect(update_layout)
	mouse_exited.connect(set_hovered_location.bind(null))
	update_layout()


func refresh_character_markers() -> void:
	var placements := PlayerState.social_locations()
	var story_characters: Array[String] = []
	for character: String in placements:
		if PlayerState.has_character_story(character, placements[character]):
			story_characters.append(character)
	if placements == last_character_locations and story_characters == last_story_characters:
		return
	set_hovered_character("")
	last_character_locations = placements
	last_story_characters = story_characters
	for child in character_markers.get_children():
		character_markers.remove_child(child)
		child.queue_free()
	for location: MapLocation in locations.get_children():
		if location.destination_scene == null or location.character_marker_position == Vector2.ZERO:
			continue
		var group := HBoxContainer.new()
		group.name = location.name
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_theme_constant_override("separation", int(MARKER_GAP))
		for character: String in placements:
			if placements[character] != location.destination_scene.resource_path:
				continue
			var badge := CharacterBadge.new()
			badge.configure(SocialCharacters.avatar(character), character, MARKER_SIZE, character in story_characters)
			if character == SocialCharacters.DAOXIANG:
				badge.tooltip_text = ""
				badge.mouse_entered.connect(set_hovered_character.bind(character))
				badge.mouse_exited.connect(clear_hovered_character.bind(character))
			badge.pressed.connect(enter_location.bind(location))
			group.add_child(badge)
		if group.get_child_count() == 0:
			group.free()
			continue
		var width := group.get_child_count() * (MARKER_SIZE + MARKER_GAP) - MARKER_GAP
		group.position = location.character_marker_position - Vector2(width, MARKER_SIZE) * 0.5
		character_markers.add_child(group)


func update_layout() -> void:
	var texture_size := map_image.texture.get_size()
	var artwork_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	artwork.scale = Vector2.ONE * artwork_scale
	artwork.position = (size - texture_size * artwork_scale) * 0.5
	var hint_scale := minf(size.x / 1152.0, size.y / 648.0)
	hover_card.size = Vector2(560, 76)
	hover_card.scale = Vector2.ONE * hint_scale
	hover_card.position = Vector2((size.x - 560.0 * hint_scale) * 0.5, size.y - 94.0 * hint_scale)
	hover_text.position = Vector2(20, 9)
	hover_text.size = Vector2(520, 58)


func get_location_at(pointer: Vector2) -> MapLocation:
	if artwork.scale.x <= 0.0:
		return null
	var source_point := artwork.transform.affine_inverse() * pointer
	for location: MapLocation in locations.get_children():
		if Geometry2D.is_point_in_polygon(source_point, location.polygon):
			return location
	return null


func set_hovered_location(location: MapLocation) -> void:
	if location == hovered_location:
		return
	if hovered_location != null:
		hovered_location.set_hovered(false)
	hovered_location = location
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if location != null else Control.CURSOR_ARROW
	if hovered_location != null:
		hovered_location.set_hovered(true)


func set_hovered_character(character: String) -> void:
	hovered_character = character
	update_hover_hint()


func clear_hovered_character(character: String) -> void:
	if hovered_character == character:
		set_hovered_character("")


func update_hover_hint() -> void:
	hover_card.visible = hovered_character == SocialCharacters.DAOXIANG and PlayerState.available_daoxiang_act() > 0
	if not hover_card.visible:
		return
	match PlayerState.available_daoxiang_act():
		1: hover_text.text = "公园 · 6～10岁散步，或许会遇见写诗的女孩"
		2: hover_text.text = "稻香粽子 · 第二幕｜河流没有回答"
		3: hover_text.text = "稻香粽子 · 第三幕｜世界没有童话，我们还有彼此"
		_: hover_text.text = "公园 · 沿着小路散步"


func _gui_input(event: InputEvent) -> void:
	if opening_destination or is_instance_valid(destination_overlay):
		return
	if event is InputEventMouseMotion:
		set_hovered_location(get_location_at(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var location := get_location_at(event.position)
		set_hovered_location(location)
		if event.pressed:
			pressed_location = location
			if pressed_location != null:
				pressed_location.set_held(true)
		elif pressed_location != null:
			var released_location := pressed_location
			pressed_location = null
			released_location.set_held(false)
			if location == released_location:
				enter_location(released_location)


func enter_location(location: MapLocation) -> void:
	if opening_destination or is_instance_valid(destination_overlay) or location.destination_scene == null:
		return
	opening_destination = true
	var click_animation := location.play_click()
	await click_animation.finished
	await SceneFade.play_action(show_destination.bind(location.destination_scene))
	opening_destination = false


func show_destination(scene: PackedScene) -> void:
	set_hovered_location(null)
	set_hovered_character("")
	character_markers.hide()
	destination_overlay = scene.instantiate() as Control
	destination_overlay.tree_exited.connect(character_markers.show)
	add_child(destination_overlay)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if is_instance_valid(destination_overlay):
			return
		get_viewport().set_input_as_handled()
		if not opening_destination:
			SceneFade.play_action(queue_free, -1.0)
