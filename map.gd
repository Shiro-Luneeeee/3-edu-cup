extends ColorRect

const MapLocation := preload("res://map_location.gd")

@onready var artwork: Node2D = $Artwork
@onready var map_image: Sprite2D = $Artwork/MapImage
@onready var locations: Node2D = $Artwork/Locations

var hovered_location: MapLocation
var pressed_location: MapLocation
var destination_overlay: Control
var opening_destination := false


func _ready() -> void:
	for location: MapLocation in locations.get_children():
		location.configure(map_image.texture)
	resized.connect(update_layout)
	mouse_exited.connect(set_hovered_location.bind(null))
	update_layout()


func update_layout() -> void:
	var texture_size := map_image.texture.get_size()
	var artwork_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	artwork.scale = Vector2.ONE * artwork_scale
	artwork.position = (size - texture_size * artwork_scale) * 0.5


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
