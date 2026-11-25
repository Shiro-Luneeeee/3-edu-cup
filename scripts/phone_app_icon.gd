extends TextureButton

@onready var art: TextureRect = $Art

var hovered := false
var held := false
var animation: Tween

func _ready() -> void:
	art.resized.connect(center_pivot)
	mouse_entered.connect(set_hovered.bind(true))
	mouse_exited.connect(set_hovered.bind(false))
	button_down.connect(set_held.bind(true))
	button_up.connect(set_held.bind(false))
	visibility_changed.connect(reset_when_hidden)
	center_pivot()

func center_pivot() -> void:
	art.pivot_offset = art.size / 2.0

func set_hovered(value: bool) -> void:
	hovered = value
	update_appearance(false)

func set_held(value: bool) -> void:
	held = value
	update_appearance(not held)

func update_appearance(releasing: bool) -> void:
	if animation:
		animation.kill()
	var target_scale := Vector2.ONE
	var tint := Color.WHITE
	if held:
		target_scale *= 0.90
		tint = Color(0.86, 0.83, 0.91)
	elif hovered:
		target_scale *= 1.08
		tint = Color(1.25, 1.22, 1.28)
	var duration := 0.17 if releasing else 0.11
	animation = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT)
	animation.tween_property(art, "scale", target_scale, duration).set_trans(Tween.TRANS_BACK if releasing else Tween.TRANS_QUAD)
	animation.tween_property(art, "self_modulate", tint, duration).set_trans(Tween.TRANS_QUAD)

func reset_when_hidden() -> void:
	if is_visible_in_tree():
		return
	if animation:
		animation.kill()
	hovered = false
	held = false
	art.scale = Vector2.ONE
	art.self_modulate = Color.WHITE
