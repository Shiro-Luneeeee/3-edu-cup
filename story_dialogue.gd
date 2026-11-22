extends Control

signal completed
signal preview_cancelled

const LISTENING_TINT := Color(0.60, 0.57, 0.64)
const BACKGROUND_FADE_TIME := 0.32

@onready var art: TextureRect = %Background
@onready var outgoing_background: TextureRect = %OutgoingBackground
@onready var stage: Control = $Stage
@onready var yue_portrait: TextureRect = %YuePortrait
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var name_tag: PanelContainer = %NameTag
@onready var speaker_name: Label = %Speaker
@onready var dialogue: Label = %Dialogue
@onready var next_button: Button = %Next

var line_index := -1
var background_fade: Tween
var preview_only := false


func _ready() -> void:
	resized.connect(place_portrait)
	dialogue_box.item_rect_changed.connect(place_portrait)
	next_button.pressed.connect(advance)
	advance()


func lines() -> Array:
	return []


func stage_line(_line: Dictionary) -> String:
	return ""


func final_button_text() -> String:
	return "继续  ›"


func advance() -> void:
	var story_lines := lines()
	if line_index >= story_lines.size():
		return
	line_index += 1
	if line_index == story_lines.size():
		completed.emit()
		return
	var line: Dictionary = story_lines[line_index]
	speaker_name.text = stage_line(line)
	name_tag.visible = not speaker_name.text.is_empty()
	dialogue.text = str(line["text"]).replace("/name", PlayerState.player_name)
	next_button.text = "继续  ›"
	if line_index == story_lines.size() - 1:
		next_button.text = "查看专属卡  ›" if preview_only else final_button_text()


func show_background(texture: Texture2D) -> Tween:
	if texture == null or texture == art.texture:
		return null
	var previous := art.texture
	art.texture = texture
	if previous == null:
		return null
	if background_fade != null:
		background_fade.kill()
		if outgoing_background.self_modulate.a > 0.5:
			previous = outgoing_background.texture
	outgoing_background.texture = previous
	outgoing_background.self_modulate.a = 1.0
	background_fade = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	background_fade.tween_property(outgoing_background, "self_modulate:a", 0.0, BACKGROUND_FADE_TIME)
	background_fade.finished.connect(finish_background_fade, CONNECT_ONE_SHOT)
	return background_fade


func finish_background_fade() -> void:
	outgoing_background.texture = null
	background_fade = null


func show_yue_background(texture: Texture2D, show_portrait: bool) -> void:
	var fade := show_background(texture)
	if fade == null:
		yue_portrait.self_modulate.a = 1.0
		yue_portrait.visible = show_portrait
		return
	var half_time := BACKGROUND_FADE_TIME * 0.5
	if show_portrait:
		yue_portrait.self_modulate.a = 0.0
		yue_portrait.show()
		fade.parallel().tween_property(yue_portrait, "self_modulate:a", 1.0, half_time).set_delay(half_time)
	elif yue_portrait.visible:
		fade.parallel().tween_property(yue_portrait, "self_modulate:a", 0.0, half_time)
		fade.finished.connect(yue_portrait.hide, CONNECT_ONE_SHOT)


func place_portrait() -> void:
	place_portrait_at(yue_portrait, 0.77)


func place_portrait_at(portrait: TextureRect, horizontal_position: float) -> void:
	if portrait.texture == null:
		return
	var frame_size := portrait.texture.get_size()
	var bottom := dialogue_box.position.y
	var height_limit := maxf(0.0, minf(size.y * 0.43, bottom - 12.0))
	var factor := minf(size.x * 0.34 / frame_size.x, height_limit / frame_size.y)
	portrait.size = frame_size * factor
	portrait.position = Vector2(size.x * horizontal_position, bottom + 2.0) - portrait.size * Vector2(0.5, 1.0)


func shake_stage(intensity: float = 1.0) -> void:
	stage.pivot_offset = stage.size * 0.5
	stage.scale = Vector2.ONE * (1.0 + 0.035 * intensity)
	var strength := minf(14.0, stage.size.x * 0.012)
	var shake := create_tween()
	shake.tween_property(stage, "position", Vector2(-strength, -4) * intensity, 0.045)
	shake.tween_property(stage, "position", Vector2(strength, 3) * intensity, 0.055)
	shake.tween_property(stage, "position", Vector2(-strength * 0.45, 0) * intensity, 0.045)
	shake.tween_property(stage, "position", Vector2.ZERO, 0.085)
	shake.tween_property(stage, "scale", Vector2.ONE, 0.10)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		advance()


func _unhandled_key_input(event: InputEvent) -> void:
	if preview_only and event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_I or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			preview_cancelled.emit()
			return
	if not event.is_echo() and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		get_viewport().set_input_as_handled()
		advance()
