extends Control

@onready var body: Label = %Body
@onready var okay_button: Button = %OkayButton


func _ready() -> void:
	hide()
	okay_button.pressed.connect(hide)


func show_message(message: String) -> void:
	body.text = message
	show()
	okay_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		hide()
