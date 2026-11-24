extends "res://main.gd"

signal effect_confirmed

enum Step { OVERVIEW, PROGRESS, BLOCK, END_TURN, RESOLVING, RECOVER, COMPLETE }

const PROGRESS_CARD := 3
const BLOCK_CARD := 2
const RECOVER_CARD := 4
const PRACTICE_ATTACK := 0
const PRACTICE_CARDS := {
	Step.PROGRESS: PROGRESS_CARD,
	Step.BLOCK: BLOCK_CARD,
	Step.RECOVER: RECOVER_CARD,
}
const LESSONS := [
	["牌局练习", "正式考试最多五回合，进度达标即可交卷。五回合内未达标，或心态降到 0，考试就会失败。每回合有 3 点能量，用来支付卡牌左上角的费用。"],
	["用卡牌推进进度", "「认真听讲」消耗 1 点能量，提供 6 点进度。先点击这张牌，再点击一个亮起的卡槽。"],
	["用格挡保护心态", "「深呼吸」不消耗能量，提供 3 点格挡。打出它，准备抵挡下一次攻击。这个回合已经用过的普通卡槽不能再用。"],
	["结束回合", "按空格或点击下方按钮。下一回合会恢复能量并抽两张牌，随后对手会攻击，先消耗格挡，再扣心态。"],
	["对手即将攻击", "这次攻击有 6 点伤害，刚才的格挡会挡住 3 点。"],
	["回复心态", "刚才少了 3 点心态。「课间休息」消耗 1 点能量，回复最多 4 点心态，并提供 3 点格挡。把它打出去试试。"],
	["练习完成", "练习中的牌和数值会清空。接下来选自己的卡牌，正式考试会从满心态、零进度开始。"],
]

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
	enemy_damage_bonus = 0
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
		Step.BLOCK: show_step(Step.END_TURN)
		Step.RECOVER: show_step(Step.COMPLETE)
	return true


func animate_card_play(card: Control, slot: Control) -> void:
	hide_guide()
	await super.animate_card_play(card, slot)


func apply_card_effect(card_id: int, slot: Control, multiplier: float) -> bool:
	var explanation: String
	match step:
		Step.PROGRESS: explanation = "这张牌会增加 6 点进度。留意进度条的变化，达到目标后就能交卷。"
		Step.BLOCK: explanation = "这张牌会增加 3 点格挡。受到攻击时，会先扣格挡，再扣心态。"
		Step.RECOVER: explanation = "这张牌会回复心态，并提供 3 点格挡。心态最多回复到上限。"
	await explain_effect(LESSONS[step][0], explanation, "查看效果")
	if leaving:
		return false
	var ends_turn := await super.apply_card_effect(card_id, slot, multiplier)
	if health_display_tween and health_display_tween.is_running():
		await health_display_tween.finished
	if progress_fill_tween and progress_fill_tween.is_running():
		await progress_fill_tween.finished
	return ends_turn


func end_turn() -> void:
	if step != Step.END_TURN or leaving or card_effect_resolving or resolving_attack or showing_turn_banner:
		return
	step = Step.RESOLVING
	hide_guide()
	await super.end_turn()
	if not leaving:
		show_step(Step.RECOVER)


func resolve_attack(_attack_id: int) -> void:
	if leaving:
		return
	await explain_effect(LESSONS[step][0], LESSONS[step][1], "播放攻击")
	if not leaving:
		await super.resolve_attack(PRACTICE_ATTACK)


func settle_game(_automatic: bool) -> void:
	# Practice never records an exam result or creates a reward.
	pass


func show_step(next: Step) -> void:
	step = next
	guide_panel.show()
	guide_title.text = LESSONS[step][0]
	guide_body.text = LESSONS[step][1]
	guide_action.visible = step == Step.OVERVIEW or step == Step.END_TURN or step == Step.COMPLETE
	match step:
		Step.OVERVIEW: guide_action.text = "开始练习"
		Step.END_TURN: guide_action.text = "结束回合"
		Step.COMPLETE: guide_action.text = "进入选牌"
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
		Step.END_TURN: end_turn()
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
	var width := minf(450.0, maxf(0.0, guide.size.x - 40.0))
	guide_panel.custom_minimum_size.x = width
	guide_panel.size = Vector2(width, 0.0)
	var x := (guide.size.x - width) * 0.5
	if step == Step.RESOLVING and guide.size.x >= 1000.0:
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
	if waiting_for_effect or card_effect_resolving or step == Step.END_TURN:
		var meter := progress_fill if step == Step.PROGRESS else health_fill
		return (meter.get_parent() as Control).get_global_rect()
	if step == Step.OVERVIEW or step == Step.COMPLETE:
		return (progress_fill.get_parent() as Control).get_global_rect()
	var card_id: int = PRACTICE_CARDS.get(step, -1)
	for card: Control in hand_holder.get_children():
		if int(card.get_meta("card_id")) == card_id:
			return card.get_global_rect()
	return Rect2()
