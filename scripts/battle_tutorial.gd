extends "res://scripts/main.gd"

signal effect_confirmed

enum Step {
	OVERVIEW, PROGRESS, BLOCK, BLOCK_DEMO, END_TURN,
	NEGATIVE_DRAW, NORMAL_DRAW, PLAY_NEGATIVE, RECOVER,
	SETTLEMENT, COMPLETE,
}

const PROGRESS_CARD := 3
const BLOCK_CARD := 2
const RECOVER_CARD := 4
const PRACTICE_CARDS := {
	Step.PROGRESS: PROGRESS_CARD,
	Step.BLOCK: BLOCK_CARD,
	Step.PLAY_NEGATIVE: Negative.DISTRACTION,
	Step.RECOVER: RECOVER_CARD,
}
const LESSONS := [
	["牌局练习", "用卡牌推进考试进度，同时留意左上角的心态。每回合基础能量为 3，卡牌左上角标着出牌费用。接下来用一局练习熟悉这些操作。"],
	["用卡牌推进进度", "「认真听讲」花费 1 点能量，增加 12 点进度。先点击这张手牌，再点击一个亮起的卡槽。"],
	["用格挡保护心态", "普通卡槽每回合只能用一次。找一个还空着的卡槽，打出 0 费的「深呼吸」，获得 3 点格挡。"],
	["格挡怎样生效", "接下来模拟 6 点伤害。先消耗 3 点格挡，剩下的 3 点才会从心态扣除。"],
	["结束回合会消耗心态", "按空格结束回合。第几回合结束就扣几点心态；学龄前每回合额外扣 0 点，7 岁起额外扣 1 点，10 岁起额外扣 2 点，此后每三年再加 1 点。这项消耗会直接扣心态。练习的第 1 回合扣 1 点。"],
	["先抽负面牌", "每回合开始先判定是否抽取一张负面牌。满心态时不会抽，心态越低越容易抽到，剩 20% 或更低时必抽。这次练习固定抽到「走神」。"],
	["再抽普通牌", "负面牌已经入手，现在可以抽普通牌。抽牌时如果牌库空了，会先把弃牌洗回。"],
	["打出负面牌", "把鼠标停在「走神」上可以查看卡面。选中它，再点击一个亮起的卡槽打出。"],
	["回复心态", "现在试试「课间休息」。它花费 1 点能量，最多回复 4 点心态，并提供 3 点格挡。"],
	["交卷与奖励", "进度达标后可以提前交卷。心态归零或第 5 回合结束也会结算，普通考试均可进入下一轮。\n低于目标无奖励，达标可选一次奖励，达到 150% 可选两次。精力上限奖励的基础加成是 5 点。"],
	["练习完成", "游戏从 0 金钱开局，进入下一轮的基础收入是 10。考试进度超过目标的 120% 或 150% 时，今后每轮收入分别增加 1 或 2，可累加。\n练习中的牌、进度和心态会清空。接下来进入选牌。"],
]
const STEP_ACTIONS := {
	Step.OVERVIEW: "开始练习",
	Step.BLOCK_DEMO: "播放模拟伤害",
	Step.END_TURN: "结束回合",
	Step.SETTLEMENT: "继续",
	Step.COMPLETE: "进入选牌",
}
const CARD_EFFECT_HINTS := {
	Step.PROGRESS: "留意上方的进度条。这张牌会把进度增加 12 点。",
	Step.BLOCK: "左上角会显示你获得的 3 点格挡。",
	Step.PLAY_NEGATIVE: "点击下方按钮，查看出牌后的变化。",
	Step.RECOVER: "心态会回复 4 点，最高回到上限。蓝色部分显示这张牌额外提供的 3 点格挡。",
}

@onready var guide: Control = $GuideLayer/Guide
@onready var dimmer: ColorRect = %Dimmer
@onready var spotlight := dimmer.material as ShaderMaterial
@onready var outline: Panel = %Outline
@onready var guide_panel: PanelContainer = %GuidePanel
@onready var guide_title: Label = %GuideTitle
@onready var guide_body: Label = %GuideBody
@onready var guide_action: Button = %GuideAction
@onready var skip_button: Button = %Skip

var step := Step.OVERVIEW
var leaving := false
var waiting_for_effect := false


func _ready() -> void:
	skip_button.pressed.connect(finish_practice)
	guide_action.pressed.connect(on_guide_action)
	guide.resized.connect(layout_guide)
	hide_guide()
	await super._ready()
	if not leaving:
		show_step(Step.OVERVIEW)


func prepare_match() -> bool:
	progress_target = ExamDifficulty.FIRST_PROGRESS_TARGET
	turn_end_age_bonus = 0
	max_health = PlayerState.DEFAULT_MAX_HEALTH
	health = float(max_health)
	displayed_health = health
	health_display_target = health
	return true


func build_deck() -> void:
	deck.assign([0, 1])


func draw_starting_hand() -> void:
	hand.assign([PROGRESS_CARD, BLOCK_CARD, RECOVER_CARD])


func _input(event: InputEvent) -> void:
	if SceneFade.curtain.visible or leaving:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			finish_practice()
			return
		if event.keycode == KEY_J:
			get_viewport().set_input_as_handled()
			if SaveManager.debug_mode_enabled:
				finish_practice()
			return
	super._input(event)


func select_card_from_hand(event: InputEvent, card: Control) -> void:
	if leaving or int(card.get_meta("card_id")) != int(PRACTICE_CARDS.get(step, -1)):
		return
	await super.select_card_from_hand(event, card)


func use_selected_card(event: InputEvent, slot: Control) -> bool:
	var played := await super.use_selected_card(event, slot)
	if not played or leaving:
		return played
	match step:
		Step.PROGRESS: show_step(Step.BLOCK)
		Step.BLOCK: show_step(Step.BLOCK_DEMO)
		Step.PLAY_NEGATIVE: show_step(Step.RECOVER)
		Step.RECOVER: show_step(Step.SETTLEMENT)
	return true


func animate_card_play(card: Control, slot: Control) -> void:
	hide_guide()
	await super.animate_card_play(card, slot)


func apply_card_effect(card_id: int, slot: Control, multiplier: float) -> bool:
	await explain_effect(LESSONS[step][0], CARD_EFFECT_HINTS[step], "查看效果")
	if leaving:
		return false
	var ends_turn := await super.apply_card_effect(card_id, slot, multiplier)
	if health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	if progress_fill_tween and progress_fill_tween.is_running():
		await progress_fill_tween.finished
	return ends_turn


func end_turn() -> void:
	if step != Step.END_TURN or leaving or card_effect_resolving or resolving_turn or showing_turn_banner:
		return
	step = Step.NEGATIVE_DRAW
	hide_guide()
	await super.end_turn()
	if not leaving:
		show_step(Step.PLAY_NEGATIVE)


func demonstrate_block() -> void:
	hide_guide()
	consume_health(6.0)
	update_values()
	if health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	if not leaving:
		show_step(Step.END_TURN)


func draw_turn_negative_card() -> void:
	await explain_effect(LESSONS[step][0], LESSONS[step][1], "抽负面牌")
	if leaving:
		return
	await give_negative_card(Negative.DISTRACTION)
	if leaving:
		return
	step = Step.NORMAL_DRAW
	await explain_effect(LESSONS[step][0], LESSONS[step][1], "抽普通牌")


func settle_game(_automatic: bool) -> void:
	# Practice never records an exam result or creates a reward.
	pass


func show_step(next: Step) -> void:
	step = next
	guide_panel.show()
	guide_title.text = LESSONS[step][0]
	guide_body.text = LESSONS[step][1]
	guide_action.visible = STEP_ACTIONS.has(step)
	guide_action.text = STEP_ACTIONS.get(step, "")
	dimmer.show()
	layout_guide()


func explain_effect(title: String, explanation: String, action: String) -> void:
	if leaving:
		return
	waiting_for_effect = true
	guide_title.text = title
	guide_body.text = explanation
	guide_action.text = action
	guide_action.show()
	guide_panel.show()
	dimmer.show()
	layout_guide()
	await effect_confirmed


func hide_guide() -> void:
	guide_panel.hide()
	dimmer.hide()
	outline.hide()


func on_guide_action() -> void:
	if leaving or SceneFade.curtain.visible:
		return
	if waiting_for_effect:
		waiting_for_effect = false
		hide_guide()
		effect_confirmed.emit()
		return
	match step:
		Step.OVERVIEW: show_step(Step.PROGRESS)
		Step.BLOCK_DEMO:
			if guide_panel.visible:
				demonstrate_block()
		Step.END_TURN: end_turn()
		Step.SETTLEMENT: show_step(Step.COMPLETE)
		Step.COMPLETE: finish_practice()


func finish_practice() -> void:
	if leaving or SceneFade.curtain.visible:
		return
	leaving = true
	game_over = true
	if waiting_for_effect:
		waiting_for_effect = false
		effect_confirmed.emit()
	PlayerState.battle_tutorial_seen = true
	SceneFade.change_to(SceneFade.starter_deck_entry_scene())


func layout_guide() -> void:
	var beside_preview := step == Step.PLAY_NEGATIVE and guide.size.x >= 1000.0
	var width := minf(390.0 if beside_preview else 450.0, maxf(0.0, guide.size.x - 40.0))
	guide_panel.custom_minimum_size.x = width
	guide_panel.size = Vector2(width, 0.0)
	var x := (guide.size.x - width) * 0.5
	if beside_preview:
		x = 14.0
	guide_panel.position = Vector2(x, clampf(guide.size.y * 0.22, 69.0, 142.0))


func _process(_delta: float) -> void:
	if leaving or progress_fill == null or guide.size.x <= 0.0 or guide.size.y <= 0.0:
		return
	var hint: String = LESSONS[step][1]
	if selected_card != null:
		hint = "点击一个亮起的卡槽出牌。右键可取消选中的牌。"
	if not waiting_for_effect and guide_body.text != hint:
		guide_body.text = hint
		layout_guide()
	var viewport_rect := Rect2(Vector2.ZERO, guide.size)
	var target := lesson_target()
	var hole := target.grow(7.0).intersection(viewport_rect)
	outline.visible = dimmer.visible and target.has_area() and hole.has_area()
	if not outline.visible:
		spotlight.set_shader_parameter("hole_rect", Vector4(-1.0, -1.0, -1.0, -1.0))
		return
	outline.position = hole.position
	outline.size = hole.size
	var start := hole.position / guide.size
	var end := hole.end / guide.size
	spotlight.set_shader_parameter("hole_rect", Vector4(start.x, start.y, end.x, end.y))


func lesson_target() -> Rect2:
	if selected_card != null:
		var targets := Rect2()
		for slot: Control in slot_layer.get_children():
			if can_use_slot(slot):
				var rect := slot.get_global_rect()
				targets = targets.merge(rect) if targets.has_area() else rect
		return targets
	if step in [Step.BLOCK_DEMO, Step.END_TURN, Step.NEGATIVE_DRAW] or (PRACTICE_CARDS.has(step) and (waiting_for_effect or card_effect_resolving)):
		var meter := progress_fill if step == Step.PROGRESS else health_fill
		return (meter.get_parent() as Control).get_global_rect()
	if step in [Step.OVERVIEW, Step.SETTLEMENT]:
		return (progress_fill.get_parent() as Control).get_global_rect()
	var card_id: int = Negative.DISTRACTION if step == Step.NORMAL_DRAW else PRACTICE_CARDS.get(step, -1)
	for card: Control in hand_holder.get_children():
		if int(card.get_meta("card_id")) == card_id:
			return card.get_global_rect()
	return Rect2()
