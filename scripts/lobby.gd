extends Control

const MATCH_SCENE := "res://scenes/card.tscn"
const BEDROOM_SCENE := "res://scenes/bedroom.tscn"
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const ExamDifficulty := preload("res://scripts/exam_difficulty.gd")

@onready var start_button: Button = $LobbyPanel/Margin/Column/StartButton
@onready var back_button: Button = $LobbyPanel/Margin/Column/BackButton
@onready var title: Label = $LobbyPanel/Margin/Column/Title
@onready var subtitle: Label = $LobbyPanel/Margin/Column/Subtitle
@onready var match_info: Label = $LobbyPanel/Margin/Column/MatchInfo
@onready var footer_note: Label = $LobbyPanel/Margin/Column/FooterNote


func _ready() -> void:
	if RoundCalendar.is_final_exam(PlayerState.round_number):
		title.text = "高考准备"
		subtitle.text = "铃声只响一次。愿此刻的勇气，与你一路同行。"
		footer_note.text = "开考后退场，这段旅程便在此落幕。"
		start_button.text = "参加高考"
	else:
		title.text = "牌局准备"
		subtitle.text = "光落在桌沿，下一页正等你写下。"
		footer_note.text = "选中手牌，再落在桌上的卡槽。"
	var target := ExamDifficulty.progress_target(PlayerState.passed_exams)
	var damage_bonus := ExamDifficulty.damage_bonus(PlayerState.passed_exams)
	match_info.text = "目标进度 %d  ·  初始心态 %d\n每回合能量 3  ·  对手伤害 +%d" % [target, PlayerState.max_health, damage_bonus]
	start_button.add_to_group("silent_match_start")
	start_button.pressed.connect(start_match)
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
