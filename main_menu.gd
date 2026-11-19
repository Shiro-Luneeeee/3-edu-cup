extends Control

const BEDROOM_SCENE := "res://bedroom.tscn"
const SETTINGS_SCENE := preload("res://settings.tscn")
const GALLERY_SCENE := preload("res://gallery.tscn")
const MAX_RIPPLES := 16
const RIPPLE_LIFETIME := 1.65

@onready var background: ColorRect = $Background
@onready var flower_glow: ColorRect = $FlowerGlow
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var gallary_button: TextureButton = $MenuColumn/GallaryButton
@onready var continue_button: TextureButton = $MenuColumn/ContinueButton
@onready var new_game_button: TextureButton = $MenuColumn/NewGameButton
@onready var settings_button: TextureButton = $MenuColumn/SettingsButton
@onready var menu_notice: AcceptDialog = $MenuNotice

var ripple_material: ShaderMaterial
var flower_glow_material: ShaderMaterial
var ripple_data: Array[Vector4] = []
var spawn_timer := 0.0
var settings_overlay: Control
var gallery_overlay: Control


func _ready() -> void:
	ripple_material = background.material.duplicate() as ShaderMaterial
	background.material = ripple_material
	flower_glow_material = flower_glow.material.duplicate() as ShaderMaterial
	flower_glow.material = flower_glow_material
	flower_glow_material.set_shader_parameter("reveal_progress", -0.12)
	create_tween().tween_property(flower_glow_material, "shader_parameter/reveal_progress", 1.12, 3.8).set_delay(0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var music_stream := menu_music.stream.duplicate() as AudioStreamMP3
	music_stream.loop = true
	menu_music.stream = music_stream
	menu_music.play()
	new_game_button.pressed.connect(start_new_game)
	continue_button.pressed.connect(func() -> void: show_notice("目前没有可继续的存档"))
	gallary_button.pressed.connect(open_gallery)
	settings_button.pressed.connect(open_settings)
	for index in 5:
		spawn_ripple(randf_range(0.0, RIPPLE_LIFETIME * 0.8))
	spawn_timer = randf_range(0.12, 0.30)
	update_shader_ripples()


func start_new_game() -> void:
	PlayerState.reset()
	StudyProgress.reset()
	SceneFade.change_to(BEDROOM_SCENE)


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


func show_notice(message: String) -> void:
	menu_notice.dialog_text = message
	menu_notice.popup_centered(Vector2i(420, 160))


func open_settings() -> void:
	if is_instance_valid(settings_overlay):
		return
	settings_overlay = SETTINGS_SCENE.instantiate() as Control
	add_child(settings_overlay)
	settings_overlay.tree_exited.connect(func() -> void: settings_overlay = null)


func open_gallery() -> void:
	if is_instance_valid(gallery_overlay):
		return
	menu_music.stream_paused = true
	gallery_overlay = GALLERY_SCENE.instantiate() as Control
	add_child(gallery_overlay)
	gallery_overlay.tree_exited.connect(resume_menu_after_gallery)


func resume_menu_after_gallery() -> void:
	gallery_overlay = null
	menu_music.stream_paused = false
