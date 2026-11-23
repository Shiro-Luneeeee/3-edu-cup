extends Control

const CardCatalog := preload("res://card_catalog.gd")
const ButtonMotion := preload("res://phone_app_icon.gd")
const MATCH_SCENE := "res://card.tscn"
const LOBBY_SCENE := "res://lobby.tscn"
const OFFER_SIZE := 3

@onready var choices: HBoxContainer = $Center/Content/Choices
@onready var counter: Label = $Center/Content/Counter
@onready var end_button: TextureButton = $Center/Content/Footer/End

var card_pool: Array[int] = []
var drafted_cards: Array[int] = []
var offered_cards: Array[int] = []
var finishing := false


func _ready() -> void:
	card_pool = CardCatalog.available_ids()
	end_button.pressed.connect(finish_draft)
	resized.connect(update_card_sizes)
	show_offer()


func show_offer() -> void:
	for previous in choices.get_children():
		choices.remove_child(previous)
		previous.queue_free()
	counter.text = "卡组 %d / %d" % [drafted_cards.size(), PlayerState.MAX_STARTER_DECK_SIZE]
	end_button.visible = drafted_cards.size() >= PlayerState.MIN_STARTER_DECK_SIZE
	var shuffled := card_pool.duplicate()
	shuffled.shuffle()
	offered_cards = shuffled.slice(0, OFFER_SIZE)
	for card_id in offered_cards:
		var button := TextureButton.new()
		button.set_script(ButtonMotion)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.set_meta("card_id", card_id)
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = CardCatalog.texture(card_id)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(art)
		art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		button.pressed.connect(choose_card.bind(card_id))
		choices.add_child(button)
	update_card_sizes()


func update_card_sizes() -> void:
	var card_width := minf(246.0, minf(size.x * 0.235, size.y * 0.39))
	for button: Control in choices.get_children():
		button.custom_minimum_size = Vector2(card_width, card_width * 1.4)


func choose_card(card_id: int) -> void:
	if finishing or not offered_cards.has(card_id):
		return
	drafted_cards.append(card_id)
	if drafted_cards.size() == PlayerState.MAX_STARTER_DECK_SIZE:
		finish_draft()
	else:
		show_offer()


func finish_draft() -> void:
	if finishing or drafted_cards.size() < PlayerState.MIN_STARTER_DECK_SIZE:
		return
	finishing = true
	counter.text = "卡组 %d / %d" % [drafted_cards.size(), PlayerState.MAX_STARTER_DECK_SIZE]
	PlayerState.finish_starter_deck(drafted_cards)
	var destination := StatRewards.take_draft_destination(MATCH_SCENE)
	StatRewards.continue_after_rewards(SceneFade.change_to.bind(destination))


func _unhandled_key_input(event: InputEvent) -> void:
	if not finishing and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		SceneFade.change_to(StatRewards.take_draft_destination(LOBBY_SCENE), -1.0)
