extends Control

const MATCH_SCENE := "res://card.tscn"
const BEDROOM_SCENE := "res://bedroom.tscn"
const CardCatalog := preload("res://card_catalog.gd")
const RoundCalendar := preload("res://round_calendar.gd")
const ExamDifficulty := preload("res://exam_difficulty.gd")

@onready var start_button: Button = $LobbyPanel/Margin/Column/StartButton
@onready var cards_button: Button = $LobbyPanel/Margin/Column/CardsButton
@onready var rules_button: Button = $LobbyPanel/Margin/Column/RulesButton
@onready var back_button: Button = $LobbyPanel/Margin/Column/BackButton
@onready var cards_dialog: AcceptDialog = $CardsDialog
@onready var rules_dialog: AcceptDialog = $RulesDialog


func _ready() -> void:
	if RoundCalendar.is_final_exam(PlayerState.round_number):
		$LobbyPanel/Margin/Column/Title.text = "高考准备"
		$LobbyPanel/Margin/Column/Subtitle.text = "高考只有一次。开考后退出，也会结束本次旅程。"
		start_button.text = "参加高考"
	var target := ExamDifficulty.progress_target(PlayerState.passed_exams)
	var damage_bonus := ExamDifficulty.damage_bonus(PlayerState.passed_exams)
	$LobbyPanel/Margin/Column/MatchInfo.text = "目标进度 %d   ·   敌方伤害 +%d\n初始心态：%d   ·   每回合能量：3\n点击手牌，再点击桌上的卡槽使用它。" % [target, damage_bonus, PlayerState.max_health]
	start_button.add_to_group("silent_match_start")
	start_button.pressed.connect(start_match)
	cards_dialog.dialog_text = card_overview()
	cards_button.pressed.connect(func() -> void: cards_dialog.popup_centered(Vector2i(620, 460)))
	rules_button.pressed.connect(func() -> void: rules_dialog.popup_centered(Vector2i(620, 340)))
	back_button.pressed.connect(SceneFade.change_to.bind(BEDROOM_SCENE, -1.0))


func start_match() -> void:
	if PlayerState.final_exam_started:
		SceneFade.change_to(SceneFade.FINAL_EXAM_ENDING_SCENE)
		return
	if not RoundCalendar.has_card_match(PlayerState.round_number):
		SceneFade.change_to(BEDROOM_SCENE, -1.0)
		return
	UiSounds.play_match_start()
	SceneFade.change_to(MATCH_SCENE if PlayerState.has_starter_deck() else SceneFade.starter_deck_entry_scene(), 1.0, 0, false)


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
