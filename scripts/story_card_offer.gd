extends ColorRect

signal decided(add_to_deck: bool)

const CardCatalog := preload("res://scripts/card_catalog.gd")

var confirming_confession := false

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


func show_offer(character: String, card_id: int, preview_only: bool = false) -> void:
	title.text = "%s的专属卡牌" % character
	card_name.text = "「%s」" % CardCatalog.card_name(card_id)
	card_art.texture = CardCatalog.texture(card_id)
	if preview_only:
		%Warning.text = "预览中的选择不会写入存档。"
	else:
		UiSounds.play_story_card_reward()


func show_confession_confirmation(character: String, preview_only: bool = false) -> void:
	confirming_confession = true
	title.text = "告白剧情"
	card_art.hide()
	card_name.hide()
	%Prompt.text = "继续后将进入与%s的告白剧情。读完后，你们将成为恋人。" % character
	%Warning.visible = preview_only
	%Warning.text = "预览不会改动存档或恋人关系。"
	add_button.text = "继续告白"
	decline_button.text = "先不告白"


func _unhandled_key_input(event: InputEvent) -> void:
	if confirming_confession and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		decide(false)


func fit_panel() -> void:
	panel.custom_minimum_size.x = minf(440.0, size.x - 24.0)
	card_art.custom_minimum_size.y = clampf(size.y - 254.0, 88.0, 334.0)


func decide(add_to_deck: bool) -> void:
	if add_button.disabled:
		return
	add_button.disabled = true
	decline_button.disabled = true
	decided.emit(add_to_deck)
