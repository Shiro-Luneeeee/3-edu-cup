extends Control

signal preview_finished

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"

@onready var exam_preview: TextureRect = $ExamPreview
@onready var monologue: Label = $Monologue
@onready var credits: Control = $Credits
@onready var return_button: Button = $Credits/ReturnButton

var preview := false


func _ready() -> void:
	exam_preview.visible = preview
	if preview:
		return_button.text = "返回剧情列表"
	return_button.pressed.connect(finish_ending)

	var sequence := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if preview:
		sequence.tween_interval(1.1)
		sequence.tween_callback(exam_preview.hide)
	sequence.tween_interval(0.65)
	sequence.tween_property(monologue, "modulate:a", 1.0, 0.45)
	sequence.tween_interval(1.55)
	sequence.tween_property(monologue, "modulate:a", 0.0, 0.35)
	sequence.tween_interval(0.2)
	sequence.tween_callback(credits.show)
	sequence.tween_property(credits, "modulate:a", 1.0, 0.5)
	sequence.tween_callback(return_button.grab_focus)


func finish_ending() -> void:
	if preview:
		preview_finished.emit()
	else:
		SceneFade.change_to(MAIN_MENU_SCENE)
