extends ColorRect

signal decided(add_to_deck: bool)

const CardCatalog := preload("res://card_catalog.gd")

@onready var panel: PanelContainer = %Panel
@onready var title: Label = %Title
@onready var card_art: TextureRect = %CardArt
@onready var card_name: Label = %CardName
@onready var add_button: Button = %Add
@onready var decline_button: Button = %Decline


func _ready() -> void:
	resized.connect(fit_panel)
	fit_panel()
	add_button.pressed.connect(decide.bind(true))
	decline_button.pressed.connect(decide.bind(false))
	grab_focus()


func show_offer(character: String, card_id: int) -> void:
	title.text = "%s的专属卡牌" % character
	card_name.text = "「%s」" % CardCatalog.card_name(card_id)
	card_art.texture = CardCatalog.texture(card_id)


func fit_panel() -> void:
	panel.custom_minimum_size.x = minf(440.0, size.x - 24.0)
	card_art.custom_minimum_size.y = clampf(size.y - 254.0, 88.0, 334.0)


func decide(add_to_deck: bool) -> void:
	if add_button.disabled:
		return
	add_button.disabled = true
	decline_button.disabled = true
	decided.emit(add_to_deck)
