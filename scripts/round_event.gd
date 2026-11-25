extends ColorRect

signal completed

const Events := preload("res://scripts/round_event_catalog.gd")
const ART := {
	"home": "res://images/events/home.png",
	"street": "res://images/events/street.png",
	"school": "res://images/events/school.png",
}

@onready var panel: PanelContainer = %Panel
@onready var illustration: TextureRect = %Illustration
@onready var title: Label = %Title
@onready var story: Label = %Story
@onready var options: VBoxContainer = %Options
@onready var outcome: Label = %Outcome
@onready var continue_button: Button = %Continue
@onready var scroll: ScrollContainer = %Scroll

var event_options: Array = []


func _ready() -> void:
	resized.connect(fit_panel)
	fit_panel()
	continue_button.pressed.connect(func() -> void: completed.emit())
	keep_focus_in([continue_button])


func show_event(event_id: String) -> void:
	var details: Dictionary = Events.EVENTS[event_id]
	illustration.texture = load(ART[details["setting"]]) as Texture2D
	title.text = details["title"]
	story.text = details["body"]
	event_options = details["options"]
	var enabled_buttons: Array[Button] = []
	for index in event_options.size():
		var option: Dictionary = event_options[index]
		var effects: Dictionary = option["effects"]
		var shortage := PlayerState.round_event_shortage(effects)
		var button := Button.new()
		button.text = "%s\n%s" % [option["title"], Events.describe_effects(effects)]
		if not shortage.is_empty():
			button.text += "    ·    " + shortage
		button.disabled = not shortage.is_empty()
		button.custom_minimum_size.y = 54.0
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not button.disabled else Control.CURSOR_ARROW
		button.pressed.connect(select_option.bind(index))
		options.add_child(button)
		if not button.disabled:
			enabled_buttons.append(button)
	keep_focus_in(enabled_buttons)
	enabled_buttons[0].grab_focus()


func select_option(index: int) -> void:
	if not PlayerState.try_resolve_round_event(index):
		return
	var option: Dictionary = event_options[index]
	story.text = option["result"]
	outcome.text = Events.describe_effects(option["effects"])
	options.hide()
	outcome.show()
	continue_button.show()
	scroll.scroll_vertical = 0
	continue_button.grab_focus()


func fit_panel() -> void:
	panel.size = (size - Vector2(32, 32)).clamp(Vector2.ZERO, Vector2(700, 570))
	panel.position = (size - panel.size) * 0.5


func keep_focus_in(buttons: Array[Button]) -> void:
	for index in buttons.size():
		var button := buttons[index]
		var previous := button.get_path_to(buttons[posmod(index - 1, buttons.size())])
		var next := button.get_path_to(buttons[(index + 1) % buttons.size()])
		button.focus_previous = previous
		button.focus_next = next
		button.focus_neighbor_top = previous
		button.focus_neighbor_bottom = next
		button.focus_neighbor_left = NodePath(".")
		button.focus_neighbor_right = NodePath(".")
