extends Control

const GAME_SCENE := "res://card.tscn"
const MAX_RIPPLES := 16
const RIPPLE_LIFETIME := 1.65

@onready var background: ColorRect = $Background
@onready var start_button: Button = $MenuPanel/Margin/Column/StartButton
@onready var exit_button: Button = $MenuPanel/Margin/Column/ExitButton

var ripple_material: ShaderMaterial
var ripple_data: Array[Vector4] = []
var spawn_timer := 0.0


func _ready() -> void:
	ripple_material = background.material.duplicate() as ShaderMaterial
	background.material = ripple_material
	start_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(GAME_SCENE))
	exit_button.pressed.connect(func() -> void: get_tree().quit())
	for index in 5:
		spawn_ripple(randf_range(0.0, RIPPLE_LIFETIME * 0.8))
	spawn_timer = randf_range(0.12, 0.30)
	update_shader_ripples()


func _process(delta: float) -> void:
	for index in range(ripple_data.size() - 1, -1, -1):
		var ripple := ripple_data[index]
		ripple.z += delta
		if ripple.z >= RIPPLE_LIFETIME:
			ripple_data.remove_at(index)
		else:
			ripple_data[index] = ripple

	spawn_timer -= delta
	if spawn_timer <= 0.0:
		spawn_ripple()
		spawn_timer = randf_range(0.17, 0.38)
	update_shader_ripples()


func spawn_ripple(age: float = 0.0) -> void:
	if ripple_data.size() >= MAX_RIPPLES:
		ripple_data.remove_at(0)
	ripple_data.append(Vector4(randf_range(0.04, 0.96), randf_range(0.05, 0.95), age, randf_range(0.045, 0.145)))


func update_shader_ripples() -> void:
	var shader_ripples := PackedVector4Array()
	for ripple in ripple_data:
		shader_ripples.append(ripple)
	while shader_ripples.size() < MAX_RIPPLES:
		shader_ripples.append(Vector4(0.0, 0.0, -1.0, 0.0))
	ripple_material.set_shader_parameter("ripples", shader_ripples)
