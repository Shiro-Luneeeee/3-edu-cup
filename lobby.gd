extends Control

const MATCH_SCENE := "res://card.tscn"
const DRAFT_SCENE := "res://deck_draft.tscn"
const BEDROOM_SCENE := "res://bedroom.tscn"
const CardCatalog := preload("res://card_catalog.gd")
const RoundCalendar := preload("res://round_calendar.gd")

@onready var start_button: Button = $LobbyPanel/Margin/Column/StartButton
@onready var cards_button: Button = $LobbyPanel/Margin/Column/CardsButton
@onready var rules_button: Button = $LobbyPanel/Margin/Column/RulesButton
@onready var back_button: Button = $LobbyPanel/Margin/Column/BackButton
@onready var cards_dialog: AcceptDialog = $CardsDialog
@onready var rules_dialog: AcceptDialog = $RulesDialog


func _ready() -> void:
	$LobbyPanel/Margin/Column/MatchInfo.text = "目标：取得 100 点学习进度\n初始心态：%d   ·   每回合能量：3\n点击手牌，再点击桌上的卡槽使用它。" % PlayerState.max_health
	start_button.pressed.connect(start_match)
	cards_dialog.dialog_text = card_overview()
	cards_button.pressed.connect(func() -> void: cards_dialog.popup_centered(Vector2i(620, 460)))
	rules_button.pressed.connect(func() -> void: rules_dialog.popup_centered(Vector2i(620, 340)))
	back_button.pressed.connect(SceneFade.change_to.bind(BEDROOM_SCENE, -1.0))


func start_match() -> void:
	if not RoundCalendar.has_card_match(PlayerState.round_number):
		SceneFade.change_to(BEDROOM_SCENE, -1.0)
		return
	SceneFade.change_to(MATCH_SCENE if PlayerState.has_starter_deck() else DRAFT_SCENE)


func card_overview() -> String:
	var names_by_cost: Dictionary[int, PackedStringArray] = {}
	for card_id in CardCatalog.available_ids():
		var cost := CardCatalog.cost(card_id)
		var names: PackedStringArray = names_by_cost.get(cost, PackedStringArray())
		names.append(CardCatalog.card_name(card_id))
		names_by_cost[cost] = names
	var lines := PackedStringArray(["首次开战前，从每组随机出现的三张牌中选一张，组成 10 至 15 张的卡组。", ""])
	var costs := names_by_cost.keys()
	costs.sort()
	for cost in costs:
		lines.append("%d 费　%s" % [cost, "、".join(names_by_cost[cost])])
	return "\n".join(lines)
