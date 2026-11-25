extends ColorRect

const CardCatalog := preload("res://scripts/card_catalog.gd")
const CardFace := preload("res://scripts/card_face.gd")
const BOOK_SIZE := Vector2(1670, 942)

@onready var book: TextureRect = $BookBoard

@onready var cards: VBoxContainer = %Cards
@onready var preview: CardFace = %Preview
@onready var points: Label = %Points
@onready var selected_card: Label = %SelectedCard
@onready var operation: OptionButton = %Operation
@onready var number: OptionButton = %Number
@onready var changes: Label = %Changes
@onready var apply_button: Button = %Apply
@onready var close_button: Button = $BookBoard/CloseButton

var selected_index := 0
var fields: Array[String] = []


func _ready() -> void:
	resized.connect(update_layout)
	update_layout()
	style_book_ui()
	operation.add_item("选择一个数值 +1", CardCatalog.Upgrade.INCREASE)
	operation.add_item("选择一个数值 -1", CardCatalog.Upgrade.DECREASE)
	operation.add_item("进度 ×1.2", CardCatalog.Upgrade.BOOST_PROGRESS)
	operation.add_item("格挡／心态 ×1.2", CardCatalog.Upgrade.BOOST_DEFENSE)
	operation.select(0)
	operation.item_selected.connect(func(_index: int) -> void: update_preview())
	number.item_selected.connect(func(_index: int) -> void: update_preview())
	apply_button.pressed.connect(apply_upgrade)
	close_button.pressed.connect(close)
	apply_button.add_to_group("card_upgrade_apply")
	PlayerState.changed.connect(refresh_deck)
	refresh_deck()


func update_layout() -> void:
	var factor := minf(size.x / BOOK_SIZE.x, size.y / BOOK_SIZE.y)
	book.size = BOOK_SIZE
	book.scale = Vector2.ONE * factor
	book.position = (size - BOOK_SIZE * factor) * 0.5


func style_book_ui() -> void:
	var ink := Color("604374")
	for label: Label in [%Points, %SelectedCard, %Changes, $BookBoard/Margin/Content/Header/Title, $BookBoard/Margin/Content/Body/DeckPanel/DeckContent/Title]:
		label.add_theme_color_override("font_color", ink)
	for button: Button in [%Apply]:
		button.add_theme_color_override("font_color", ink)
		button.add_theme_color_override("font_hover_color", Color("9a5d88"))
		button.add_theme_color_override("font_pressed_color", ink)


func refresh_deck() -> void:
	points.text = "升级点 %d" % PlayerState.upgrade_points
	for child in cards.get_children():
		cards.remove_child(child)
		child.queue_free()
	for index in PlayerState.card_deck.size():
		var card_id := PlayerState.card_deck[index]
		var base_id := PlayerState.card_base_id(card_id)
		var button := Button.new()
		button.text = "%s  ·  %d 费" % [CardCatalog.card_name(base_id), PlayerState.card_cost(card_id)]
		if PlayerState.card_numbers(card_id) != CardCatalog.numbers(base_id):
			button.text += "  ·  已升级"
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 41.0
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.toggle_mode = true
		button.add_to_group("soft_selection")
		button.pressed.connect(select_card.bind(index))
		cards.add_child(button)
	select_card(clampi(selected_index, 0, maxi(0, PlayerState.card_deck.size() - 1)))


func select_card(index: int) -> void:
	selected_index = index
	var has_card := not PlayerState.card_deck.is_empty()
	preview.visible = has_card
	if not has_card:
		operation.disabled = true
		selected_card.text = "卡组为空"
		number.hide()
		changes.text = "组好初始卡组后即可升级卡牌。"
		apply_button.disabled = true
		return
	for row in cards.get_child_count():
		cards.get_child(row).set_pressed_no_signal(row == index)
	var card_id := PlayerState.card_deck[index]
	var base_id := PlayerState.card_base_id(card_id)
	selected_card.text = CardCatalog.card_name(base_id)
	var previous_field := selected_field()
	var values := PlayerState.card_numbers(card_id)
	fields.clear()
	number.clear()
	for field: String in CardCatalog.number_regions(base_id):
		fields.append(field)
		number.add_item("%s · %s" % [CardCatalog.NUMBER_NAMES[field], values[field]])
	if not fields.is_empty():
		number.select(maxi(0, fields.find(previous_field)))
	update_preview()


func selected_field() -> String:
	return fields[number.selected] if number.selected >= 0 and number.selected < fields.size() else ""


func update_preview() -> void:
	if PlayerState.card_deck.is_empty():
		return
	var card_id := PlayerState.card_deck[selected_index]
	operation.disabled = fields.is_empty()
	if fields.is_empty():
		preview.set_card(card_id)
		number.hide()
		changes.text = "这张牌的效果没有可升级的阿拉伯数字。"
		apply_button.disabled = true
		return
	var current := PlayerState.card_numbers(card_id)
	var upgrade := operation.get_selected_id()
	number.visible = upgrade == CardCatalog.Upgrade.INCREASE or upgrade == CardCatalog.Upgrade.DECREASE
	var proposed := CardCatalog.upgraded_numbers(PlayerState.card_base_id(card_id), current, upgrade, selected_field())
	preview.set_card(card_id, proposed)
	var lines := PackedStringArray()
	for field in proposed:
		if proposed[field] != current[field]:
			lines.append("%s  %s → %s" % [CardCatalog.NUMBER_NAMES[field], current[field], proposed[field]])
	var insufficient := PlayerState.upgrade_points < CardCatalog.UPGRADE_COST
	apply_button.disabled = insufficient or lines.is_empty()
	if insufficient:
		lines.append("升级点不足")
	elif lines.is_empty():
		lines.append("此选项不会改变卡牌数值")
	changes.text = "\n".join(lines)


func apply_upgrade() -> void:
	if PlayerState.try_upgrade_card(selected_index, operation.get_selected_id(), selected_field()):
		UiSounds.play_card_upgrade_success()
		preview.set_card(PlayerState.card_deck[selected_index])
		var next_upgrade := "\n再升级一次的变化\n" if not apply_button.disabled else "\n"
		changes.text = "升级成功" + next_upgrade + changes.text


func close() -> void:
	SceneFade.play_action(queue_free, -1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
