extends Control

const BEDROOM_SCENE := "res://scenes/bedroom.tscn"
const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const SETTINGS_SCENE := preload("res://scenes/settings.tscn")
const GALLERY_SCENE := preload("res://scenes/gallery.tscn")
const ModelNotice := preload("res://scripts/model_notice.gd")
const MAX_RIPPLES := 16
const RIPPLE_LIFETIME := 1.65

@onready var background: ColorRect = $Background
@onready var flower_glow: ColorRect = $FlowerGlow
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var gallary_button: TextureButton = $MenuColumn/GallaryButton
@onready var continue_button: TextureButton = $MenuColumn/ContinueButton
@onready var new_game_button: TextureButton = $MenuColumn/NewGameButton
@onready var settings_button: TextureButton = $MenuColumn/SettingsButton
@onready var menu_notice: ModelNotice = $MenuNotice

var ripple_material: ShaderMaterial
var flower_glow_material: ShaderMaterial
var ripple_data: Array[Vector4] = []
var spawn_timer := 0.0
var settings_overlay: Control
var gallery_overlay: Control
var button_feedback_tweens: Dictionary[TextureButton, Tween] = {}


func _ready() -> void:
	ripple_material = background.material.duplicate() as ShaderMaterial
	background.material = ripple_material
	flower_glow_material = flower_glow.material.duplicate() as ShaderMaterial
	flower_glow.material = flower_glow_material
	flower_glow_material.set_shader_parameter("reveal_progress", -0.12)
	create_tween().tween_property(flower_glow_material, "shader_parameter/reveal_progress", 1.12, 3.8).set_delay(0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	menu_music = SaveManager.use_scene_music(MAIN_MENU_SCENE, menu_music)
	new_game_button.pressed.connect(start_new_game)
	continue_button.visible = SaveManager.has_any_save()
	continue_button.pressed.connect(SaveManager.open_load_page)
	gallary_button.pressed.connect(open_gallery)
	settings_button.pressed.connect(open_settings)
	$MenuColumn/QuitButton.pressed.connect(func() -> void: get_tree().quit())
	for button: TextureButton in $MenuColumn.get_children():
		var ink := button.material.duplicate() as ShaderMaterial
		ink.set_shader_parameter("button_feedback", Vector2.ZERO)
		button.material = ink
		button.mouse_entered.connect(animate_menu_button.bind(button, true))
		button.mouse_exited.connect(animate_menu_button.bind(button, false))
		button.button_down.connect(animate_menu_button.bind(button, true, true))
		button.button_up.connect(func() -> void: animate_menu_button(button, button.is_hovered(), false, true))
	for index in 5:
		spawn_ripple(randf_range(0.0, RIPPLE_LIFETIME * 0.8))
	spawn_timer = randf_range(0.12, 0.30)
	update_shader_ripples()
	LocalDialogue.availability_changed.connect(_on_dialogue_checked)
	if not LocalDialogue.checking and not LocalDialogue.available:
		call_deferred("_on_dialogue_checked")


func _exit_tree() -> void:
	SaveManager.release_scene_music(MAIN_MENU_SCENE)


func animate_menu_button(button: TextureButton, hovered: bool, pressed: bool = false, releasing: bool = false) -> void:
	if button_feedback_tweens.has(button):
		button_feedback_tweens[button].kill()
	var duration := 0.17 if releasing else 0.10
	var ink := button.material as ShaderMaterial
	var current: Vector2 = ink.get_shader_parameter("button_feedback")
	if pressed:
		current.y = 0.45
		ink.set_shader_parameter("button_feedback", current)
	var target := Vector2(1.0 if hovered else 0.0, 1.0 if pressed else 0.0)
	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_method(func(value: Vector2) -> void: ink.set_shader_parameter("button_feedback", value), current, target, duration)
	button_feedback_tweens[button] = tween


func start_new_game() -> void:
	if SceneFade.curtain.visible:
		return
	PlayerState.reset()
	StudyProgress.reset()
	SaveManager.start_new_game()
	SceneFade.change_to("res://scenes/birth_prologue.tscn")


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
	menu_notice.show_message(message)


func _on_dialogue_checked() -> void:
	if not LocalDialogue.available and not LocalDialogue.checking:
		menu_notice.show_message("由于当前设备或本地模型环境不支持，社交功能中的本地模型对话暂不可用。\n\n%s\n\n其他剧情与社交操作仍可继续。" % LocalDialogue.reason)


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
