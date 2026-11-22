extends ColorRect

const MapLocation := preload("res://map_location.gd")
const PAPER: Texture2D = preload("res://images/aged_blank_a4_paper.png")

@onready var artwork: Node2D = $Artwork
@onready var map_image: Sprite2D = $Artwork/MapImage
@onready var locations: Node2D = $Artwork/Locations

var hovered_location: MapLocation
var pressed_location: MapLocation
var destination_overlay: Control
var opening_destination := false
var hover_card := TextureRect.new()
var hover_text := Label.new()


func _ready() -> void:
	for location: MapLocation in locations.get_children():
		location.configure(map_image.texture)
	var paper_fill := AtlasTexture.new()
	paper_fill.atlas = PAPER
	paper_fill.region = Rect2(PAPER.get_size() * Vector2(0.07, 0.06), PAPER.get_size() * Vector2(0.86, 0.87))
	hover_card.texture = paper_fill
	hover_card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hover_card.stretch_mode = TextureRect.STRETCH_SCALE
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.visible = false
	add_child(hover_card)
	hover_card.add_child(hover_text)
	hover_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hover_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hover_text.add_theme_font_size_override("font_size", 19)
	hover_text.add_theme_color_override("font_color", Color("514d54"))
	resized.connect(update_layout)
	mouse_exited.connect(set_hovered_location.bind(null))
	update_layout()


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
	update_hover_hint()


func update_hover_hint() -> void:
	hover_card.visible = hovered_location != null and hovered_location.name == "Park"
	if not hover_card.visible:
		return
	match PlayerState.available_daoxiang_act():
		1: hover_text.text = "公园 · 6～14岁散步，或许会遇见写诗的女孩"
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
				var click_animation := released_location.play_click()
				if released_location.destination_scene != null:
					enter_destination(released_location.destination_scene, click_animation)


func enter_destination(scene: PackedScene, click_animation: Tween) -> void:
	opening_destination = true
	await click_animation.finished
	await SceneFade.play_action(show_destination.bind(scene))
	opening_destination = false


func show_destination(scene: PackedScene) -> void:
	set_hovered_location(null)
	destination_overlay = scene.instantiate() as Control
	add_child(destination_overlay)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if is_instance_valid(destination_overlay):
			return
		get_viewport().set_input_as_handled()
		if not opening_destination:
			SceneFade.play_action(queue_free, -1.0)
