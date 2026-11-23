extends ColorRect

const SocialCharacters := preload("res://social_characters.gd")
const RoundCalendar := preload("res://round_calendar.gd")
const YuePortraits := preload("res://yue_portraits.gd")
const FushimiPortraits := preload("res://fushimi_portraits.gd")
const PRESENTATION_SIZE := Vector2(1672.0, 941.0)
const CHAT_SCENE := preload("res://social_chat.tscn")

var selected_character := ""
var chat_overlay: Control

@onready var presentation: Control = %Presentation
@onready var contacts: ItemList = get_node_or_null("%Contacts")
@onready var empty_contacts: Label = get_node_or_null("%EmptyContacts")
@onready var details: VBoxContainer = %Details
@onready var portrait: TextureRect = %Portrait
@onready var contact_name: Label = %ContactName
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var affection_readout: Label = affection_bar.get_node("Readout")
@onready var chat_button: Button = %Chat


func _ready() -> void:
	resized.connect(fit_presentation)
	PlayerState.changed.connect(refresh_details)
	chat_button.text = "自由对话"
	chat_button.pressed.connect(open_free_chat)
	%Close.pressed.connect(close)
	fit_presentation()
	affection_bar.max_value = PlayerState.AFFECTION_PER_LEVEL
	refresh_details()
	var known := PlayerState.known_social_characters()
	if known.is_empty():
		details.hide()
		if contacts != null:
			contacts.hide()
			empty_contacts.show()
		return
	var index := maxi(0, known.find(selected_character))
	if contacts != null:
		contacts.item_selected.connect(select_contact)
		for character in known:
			contacts.add_item(character, SocialCharacters.avatar(character))
		contacts.select(index)
	show_contact(known[index])


func fit_presentation() -> void:
	var factor := minf(size.x / PRESENTATION_SIZE.x, size.y / PRESENTATION_SIZE.y)
	presentation.scale = Vector2.ONE * factor
	presentation.position = (size - PRESENTATION_SIZE * factor) * 0.5
	if contacts == null and factor > 0.0:
		portrait.position.y = (size.y - presentation.position.y) / factor - portrait.size.y


func select_contact(index: int) -> void:
	show_contact(contacts.get_item_text(index))


func show_contact(character: String) -> void:
	selected_character = character
	contact_name.text = selected_character
	var age := RoundCalendar.age(PlayerState.round_number)
	if character == SocialCharacters.YUE:
		if contacts == null:
			YuePortraits.show_onsite(portrait, age)
		else:
			YuePortraits.show_on(portrait, age)
	elif character == SocialCharacters.FUSHIMI:
		FushimiPortraits.show_on(portrait, age)
	refresh_details()


func refresh_details() -> void:
	if selected_character.is_empty():
		return
	var progress := PlayerState.affection_progress(selected_character)
	var maxed := progress.x == PlayerState.MAX_AFFECTION_LEVEL
	affection_bar.value = progress.y
	var progress_text := "已满" if maxed else "%d/%d" % [progress.y, PlayerState.AFFECTION_PER_LEVEL]
	affection_readout.text = "好感度  %d 级  ·  %s" % [progress.x, progress_text]


func open_free_chat() -> void:
	if selected_character.is_empty() or is_instance_valid(chat_overlay) or SceneFade.curtain.visible:
		return
	chat_overlay = CHAT_SCENE.instantiate() as Control
	chat_overlay.set("character", selected_character)
	add_child(chat_overlay)
	chat_overlay.tree_exited.connect(func() -> void: chat_overlay = null)


func close() -> void:
	SceneFade.play_action(queue_free, -1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
