extends Control

const MATCH_TRANSITION_SCENE := preload("res://match_transition.tscn")
const MAIN_MENU_SCENE := "res://main_menu.tscn"

@onready var lobby_music: AudioStreamPlayer = $LobbyMusic
@onready var quit_button: Button = $QuitButton
@onready var study_button: Button = $StudyButton
@onready var game_button: Button = $GameButton
@onready var social_button: Button = $SocialButton
@onready var exam_button: Button = $ExamButton
@onready var notice: AcceptDialog = $Notice

var glow_labels: Array[Label] = []
var entering_match := false


func _ready() -> void:
	var music_stream := lobby_music.stream.duplicate() as AudioStreamMP3
	music_stream.loop = true
	lobby_music.stream = music_stream
	lobby_music.play()

	configure_text_button(quit_button, 36)
	configure_text_button(study_button, 44)
	configure_text_button(game_button, 44)
	configure_text_button(social_button, 35)
	configure_text_button(exam_button, 48)

	quit_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MAIN_MENU_SCENE))
	study_button.pressed.connect(func() -> void: show_notice("Study 即将开放"))
	game_button.pressed.connect(func() -> void: show_notice("Game 即将开放"))
	social_button.pressed.connect(func() -> void: show_notice("Social 即将开放"))
	exam_button.pressed.connect(start_match)


func start_match() -> void:
	if entering_match:
		return
	entering_match = true
	exam_button.disabled = true
	var transition := MATCH_TRANSITION_SCENE.instantiate()
	get_tree().root.add_child(transition)
	transition.begin(lobby_music)


func _process(_delta: float) -> void:
	var breath := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * 1.25 - PI * 0.5)
	for glow in glow_labels:
		var strength := 0.30 + breath * 0.26
		if glow.get_parent().is_hovered():
			strength += 0.25
		glow.add_theme_color_override("font_outline_color", Color(1.0, 0.82, 0.28, strength))


func configure_text_button(button: Button, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.97, 0.84))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.94))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.87, 0.55))
	button.add_theme_color_override("font_outline_color", Color(0.31, 0.22, 0.43, 0.95))
	button.add_theme_constant_override("outline_size", 4)

	var glow := Label.new()
	glow.name = "Glow"
	glow.text = button.text
	glow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	glow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.show_behind_parent = true
	button.add_child(glow)
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.add_theme_font_size_override("font_size", font_size)
	glow.add_theme_color_override("font_color", Color(1.0, 0.96, 0.74, 0.0))
	glow.add_theme_color_override("font_outline_color", Color(1.0, 0.82, 0.28, 0.55))
	glow.add_theme_constant_override("outline_size", 18)
	glow_labels.append(glow)


func show_notice(message: String) -> void:
	notice.dialog_text = message
	notice.popup_centered(Vector2i(400, 150))
