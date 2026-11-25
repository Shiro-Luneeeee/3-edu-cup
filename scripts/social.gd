extends ColorRect

const SocialCharacters := preload("res://scripts/social_characters.gd")
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const YuePortraits := preload("res://scripts/yue_portraits.gd")
const FushimiPortraits := preload("res://scripts/fushimi_portraits.gd")
const SHIRAKAWA_PORTRAIT := preload("res://images/high_school_intro/shirakawa_social_portrait.tres")
const PRESENTATION_SIZE := Vector2(1672.0, 941.0)
const CHAT_SCENE := preload("res://scenes/social_chat.tscn")

var selected_character := ""
var chat_overlay: Control
var socialize_button: Button
var social_feedback: Label

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
	create_socialize_controls()
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
		contacts.add_to_group("soft_selection")
		contacts.item_selected.connect(select_contact)
		for character in known:
			contacts.add_item(character, SocialCharacters.avatar(character))
		contacts.select(index)
	show_contact(known[index])


func create_socialize_controls() -> void:
	socialize_button = chat_button.duplicate(0) as Button
	socialize_button.name = "Socialize"
	socialize_button.unique_name_in_owner = false
	socialize_button.text = "聊天"
	socialize_button.tooltip_text = "精力 -%d\n好感度 +%d" % [
		SocialCharacters.CHAT_ENERGY_COST, SocialCharacters.CHAT_AFFECTION_GAIN
	]
	socialize_button.pressed.connect(socialize)
	details.add_child(socialize_button)
	details.move_child(socialize_button, chat_button.get_index())

	social_feedback = Label.new()
	social_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	social_feedback.add_theme_color_override("font_color", Color("67496d"))
	social_feedback.add_theme_font_size_override("font_size", 23)
	social_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(social_feedback)


func fit_presentation() -> void:
	var factor := minf(size.x / PRESENTATION_SIZE.x, size.y / PRESENTATION_SIZE.y)
	presentation.scale = Vector2.ONE * factor
	presentation.position = (size - PRESENTATION_SIZE * factor) * 0.5
	if contacts == null and factor > 0.0:
		portrait.position.y = (size.y - presentation.position.y) / factor - portrait.size.y


func select_contact(index: int) -> void:
	UiSounds.play_soft_click()
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
	elif character == SocialCharacters.SHIRAKAWA:
		portrait.material = null
		portrait.texture = SHIRAKAWA_PORTRAIT
	refresh_details()


func refresh_details() -> void:
	if selected_character.is_empty():
		return
	var progress := PlayerState.affection_progress(selected_character)
	var maxed := progress.x == PlayerState.MAX_AFFECTION_LEVEL
	affection_bar.value = progress.y
	var progress_text := "已满" if maxed else "%d/%d" % [progress.y, PlayerState.AFFECTION_PER_LEVEL]
	affection_readout.text = "好感度  %d 级  ·  %s" % [progress.x, progress_text]
	var cost := SocialCharacters.CHAT_ENERGY_COST
	socialize_button.disabled = maxed or PlayerState.current_energy < cost
	social_feedback.text = "当前精力 %s" % PlayerState.energy_text()
	if maxed:
		social_feedback.text += "  ·  好感已满"
	elif PlayerState.current_energy < cost:
		social_feedback.text += "  ·  精力不足"


func socialize() -> void:
	if selected_character.is_empty() or is_instance_valid(chat_overlay) or SceneFade.curtain.visible:
		return
	PlayerState.try_socialize(selected_character)


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
