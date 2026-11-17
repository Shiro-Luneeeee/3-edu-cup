extends Control

const IMAGE_SIZE := Vector2(1672, 941)
const CLOCK_RECT := Rect2(1000, 300, 175, 230)
const PREPARATION_SCENE := "res://lobby.tscn"

@onready var clock_button: Button = $ClockButton
@onready var clock_highlight: Polygon2D = $ClockButton/ClockHighlight

var highlight_tween: Tween

func _ready() -> void:
	resized.connect(update_clock_position)
	clock_button.mouse_entered.connect(set_clock_highlight.bind(true))
	clock_button.mouse_exited.connect(set_clock_highlight.bind(false))
	clock_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(PREPARATION_SCENE))
	update_clock_position()

func update_clock_position() -> void:
	var image_scale := minf(size.x / IMAGE_SIZE.x, size.y / IMAGE_SIZE.y)
	var image_origin := (size - IMAGE_SIZE * image_scale) / 2.0
	clock_button.position = image_origin + CLOCK_RECT.position * image_scale
	clock_button.size = CLOCK_RECT.size * image_scale
	clock_highlight.scale = Vector2.ONE * image_scale

func set_clock_highlight(hovered: bool) -> void:
	if highlight_tween:
		highlight_tween.kill()
	highlight_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	highlight_tween.tween_property(clock_highlight, "modulate:a", 1.0 if hovered else 0.0, 0.18)
