extends ColorRect

const SocialCharacters := preload("res://social_characters.gd")
const RoundCalendar := preload("res://round_calendar.gd")
const YuePortraits := preload("res://yue_portraits.gd")
const PRESENTATION_SIZE := Vector2(1672.0, 941.0)

var selected_character := ""

@onready var presentation: Control = %Presentation
@onready var contacts: ItemList = get_node_or_null("%Contacts")
@onready var details: VBoxContainer = %Details
@onready var portrait: TextureRect = %Portrait
@onready var contact_name: Label = %ContactName
@onready var affection_bar: ProgressBar = %AffectionBar
@onready var affection_readout: Label = affection_bar.get_node("Readout")
@onready var energy_bar: ProgressBar = %EnergyBar
@onready var energy_readout: Label = energy_bar.get_node("Readout")
@onready var action_effect: Label = %ActionEffect
@onready var message: Label = %Message
@onready var chat_button: Button = %Chat


func _ready() -> void:
	resized.connect(fit_presentation)
	PlayerState.changed.connect(refresh_details)
	chat_button.pressed.connect(chat)
	%Close.pressed.connect(close)
	fit_presentation()
	affection_bar.max_value = PlayerState.AFFECTION_PER_LEVEL
	refresh_details()
	var known := SocialCharacters.known_characters(PlayerState.park_meeting_seen)
	if known.is_empty():
		details.hide()
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
	if character == SocialCharacters.YUE:
		var age := RoundCalendar.age(PlayerState.round_number)
		if contacts == null:
			YuePortraits.show_onsite(portrait, age)
		else:
			YuePortraits.show_on(portrait, age)
	message.text = ""
	refresh_details()


func refresh_details() -> void:
	energy_bar.max_value = PlayerState.max_energy
	energy_bar.value = PlayerState.current_energy
	energy_readout.text = "精力  %s" % PlayerState.energy_text()
	if selected_character.is_empty():
		return
	var progress := PlayerState.affection_progress(selected_character)
	var maxed := progress.x == PlayerState.MAX_AFFECTION_LEVEL
	affection_bar.value = progress.y
	var progress_text := "已满" if maxed else "%d/%d" % [progress.y, PlayerState.AFFECTION_PER_LEVEL]
	affection_readout.text = "好感度  %d 级  ·  %s" % [progress.x, progress_text]
	var gain := PlayerState.affection_gain_for(selected_character, SocialCharacters.CHAT_AFFECTION_GAIN)
	action_effect.text = "精力 −%d   ·   好感度 +%d" % [SocialCharacters.CHAT_ENERGY_COST, gain] if not maxed else ""
	var enough_energy := PlayerState.current_energy >= SocialCharacters.CHAT_ENERGY_COST
	chat_button.disabled = maxed or not enough_energy
	var action := "发消息" if contacts != null else "聊一会儿"
	if maxed:
		action = "好感度已满"
	elif not enough_energy:
		action = "精力不足"
	chat_button.text = action


func chat() -> void:
	if SceneFade.curtain.visible:
		return
	var previous_level := PlayerState.affection_progress(selected_character).x
	var gain := PlayerState.affection_gain_for(selected_character, SocialCharacters.CHAT_AFFECTION_GAIN)
	if PlayerState.try_socialize(selected_character):
		var level := PlayerState.affection_progress(selected_character).x
		if level > previous_level:
			message.text = "好感度 +%d  ·  升至 %d 级" % [gain, level]
		else:
			var response := "%s回了消息。" % selected_character if contacts != null else "你们在这里聊了一会儿。"
			message.text = "%s 好感度 +%d" % [response, gain]


func close() -> void:
	SceneFade.play_action(queue_free, -1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
