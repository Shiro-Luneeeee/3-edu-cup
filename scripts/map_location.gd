extends Polygon2D

const CORNER_TRIM := 18.0
const CORNER_SEGMENTS := 6

@export var destination_scene: PackedScene
@export var social_location_id := ""
@export var character_marker_position := Vector2.ZERO

var outline := Line2D.new()
var click_ring := Line2D.new()
var appearance_tween: Tween
var click_tween: Tween
var hovered := false
var held := false


func configure(map_texture: Texture2D) -> void:
	texture = map_texture
	polygon = round_contour(polygon)
	uv = polygon
	self_modulate.a = 0.0
	add_child(outline)
	outline.points = polygon
	outline.closed = true
	outline.antialiased = true
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.width = 2.0
	outline.default_color = Color("fff0bc")
	outline.modulate.a = 0.0
	outline.z_index = 1

	# The flash follows the same outline and expands around the district's center.
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	center /= polygon.size()
	var ring_points := PackedVector2Array()
	for point in polygon:
		ring_points.append(point - center)
	add_child(click_ring)
	click_ring.points = ring_points
	click_ring.position = center
	click_ring.closed = true
	click_ring.antialiased = true
	click_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	click_ring.width = 3.8
	click_ring.default_color = Color("fff0bc")
	click_ring.modulate.a = 0.0
	click_ring.z_index = 2


func round_contour(points: PackedVector2Array) -> PackedVector2Array:
	var rounded := PackedVector2Array()
	for index in points.size():
		var previous := points[posmod(index - 1, points.size())]
		var corner := points[index]
		var next := points[(index + 1) % points.size()]
		var shortest_edge := minf(corner.distance_to(previous), corner.distance_to(next))
		var trim := minf(CORNER_TRIM, shortest_edge * 0.42)
		var entry := corner.move_toward(previous, trim)
		var exit := corner.move_toward(next, trim)
		# A quadratic Bézier joins the two shortened edges tangentially.
		for step in range(CORNER_SEGMENTS + 1):
			var fraction := float(step) / CORNER_SEGMENTS
			var incoming := entry.lerp(corner, fraction)
			var outgoing := corner.lerp(exit, fraction)
			rounded.append(incoming.lerp(outgoing, fraction))
	return rounded


func set_hovered(value: bool) -> void:
	hovered = value
	update_appearance()


func set_held(value: bool) -> void:
	held = value
	update_appearance()


func update_appearance() -> void:
	if appearance_tween:
		appearance_tween.kill()
	var tint := Color(1.0, 1.0, 1.0, 0.0)
	var outline_opacity := 0.0
	if hovered:
		tint = Color(1.16, 1.13, 1.05, 0.95)
		outline_opacity = 0.72
		if held:
			tint = Color(1.04, 1.01, 0.95, 0.88)
			outline_opacity = 0.45
	appearance_tween = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	appearance_tween.tween_property(self, "self_modulate", tint, 0.13)
	appearance_tween.tween_property(outline, "modulate:a", outline_opacity, 0.13)


func play_click() -> Tween:
	if click_tween:
		click_tween.kill()
	click_ring.scale = Vector2.ONE * 0.975
	click_ring.modulate.a = 0.85
	click_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	click_tween.tween_property(click_ring, "scale", Vector2.ONE * 1.04, 0.34)
	click_tween.tween_property(click_ring, "modulate:a", 0.0, 0.34)
	return click_tween
