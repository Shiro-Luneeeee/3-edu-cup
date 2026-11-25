extends Control

const FRONT_POSITION := Vector2(20.0, 140.0)
const BACK_POSITIONS := [Vector2(-35.0, 169.0), Vector2(75.0, 179.0), Vector2(4.0, 194.0), Vector2(46.0, 203.0)]
const BACK_ROTATIONS := [-0.105, 0.11, 0.035, -0.055]
const BACK_COLORS := [
	Color(0.94, 0.92, 1.0, 0.9),
	Color(1.0, 0.94, 0.94, 0.9),
	Color(0.98, 0.96, 1.0, 0.95),
	Color(0.95, 0.94, 1.0, 0.9)
]
const RoundCalendar := preload("res://scripts/round_calendar.gd")
const PAGE_TITLES := ["声音", "操作", "玩法", "关于", "调试"]
const PAGE_SUBTITLES := [
	"调节整个游戏的音量",
	"记住这些常用操作",
	"开始下一场备考",
	"请允我如夏日般融化 · 游戏信息",
	"输入调试命令，快速进入游戏"
]
const PAGE_TEXTS := [
	"",
	"点击手牌，再点击亮起的卡槽出牌。\n\n空格：结束当前回合\nJ：跳过牌局并进入下一轮（无牌局奖励）\n鼠标右键：取消已选手牌",
	"首次进入牌局前，先选出 10 至 15 张牌组成卡组。\n每局开场抽 5 张牌，之后每回合抽 2 张。\n牌库抽空时洗回弃牌。\n\n通过考试后，下一场的目标进度会上升。第五回合结束时未达标则失败。\n心态与格挡会随卡牌效果变化。",
	"",
	""
]

@onready var back_left: TextureRect = $PaperStack/BackLeft
@onready var back_right: TextureRect = $PaperStack/BackRight
@onready var back_middle: TextureRect = $PaperStack/BackMiddle
@onready var back_fourth: TextureRect = $PaperStack/BackFourth
@onready var main_paper: TextureRect = $PaperStack/MainPaper
@onready var content: Control = $PaperStack/MainPaper/Content
@onready var title_label: Label = $PaperStack/MainPaper/Content/Title
@onready var subtitle_label: Label = $PaperStack/MainPaper/Content/Subtitle
@onready var page_body: Label = $PaperStack/MainPaper/Content/PageBody
@onready var volume_label: Label = $PaperStack/MainPaper/Content/VolumeLabel
@onready var volume_slider: HSlider = $PaperStack/MainPaper/Content/VolumeSlider
@onready var volume_value: Label = $PaperStack/MainPaper/Content/VolumeValue
@onready var back_button: Button = $PaperStack/MainPaper/Content/BackButton
@onready var previous_button: Button = $PaperStack/MainPaper/Content/PreviousButton
@onready var next_button: Button = $PaperStack/MainPaper/Content/NextButton
@onready var page_number: Label = $PaperStack/MainPaper/Content/PageNumber
@onready var debug_hint: Label = $PaperStack/MainPaper/Content/DebugHint
@onready var debug_input: LineEdit = $PaperStack/MainPaper/Content/DebugInput
@onready var debug_run_button: Button = $PaperStack/MainPaper/Content/DebugRunButton
@onready var debug_feedback: Label = $PaperStack/MainPaper/Content/DebugFeedback

var papers: Array[TextureRect] = []
var page_index := 0
var is_turning := true


func _ready() -> void:
	papers = [main_paper, back_left, back_right, back_middle, back_fourth]
	var master_bus := AudioServer.get_bus_index("Master")
	if AudioServer.is_bus_mute(master_bus):
		volume_slider.value = 0.0
	else:
		volume_slider.value = roundf(db_to_linear(AudioServer.get_bus_volume_db(master_bus)) * 100.0)
	update_volume_label(volume_slider.value)
	volume_slider.value_changed.connect(set_master_volume)
	back_button.pressed.connect(close_settings)
	previous_button.pressed.connect(func() -> void: turn_page(-1))
	next_button.pressed.connect(func() -> void: turn_page(1))
	debug_input.text_submitted.connect(func(_text: String) -> void: execute_debug_command())
	debug_run_button.pressed.connect(execute_debug_command)
	for index in papers.size():
		papers[index].gui_input.connect(handle_paper_click.bind(index))
	update_page_content()
	animate_papers()


func animate_papers() -> void:
	var final_y: Array[float] = []
	for paper in papers:
		final_y.append(paper.position.y)
		paper.position.y += 700.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(back_left, "position:y", final_y[1], 1.75).set_delay(0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(back_right, "position:y", final_y[2], 1.85).set_delay(0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(back_middle, "position:y", final_y[3], 1.95).set_delay(0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(back_fourth, "position:y", final_y[4], 2.0).set_delay(0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(main_paper, "position:y", final_y[0], 2.15).set_delay(0.34).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.finished.connect(func() -> void: is_turning = false)


func turn_page(direction: int) -> void:
	if is_turning:
		return
	var target_index := page_index + direction
	if target_index < 0 or target_index >= papers.size() or target_index == page_index:
		return
	is_turning = true
	content.hide()
	var next_front: TextureRect = papers[target_index]
	# GUI hit testing follows sibling order, not CanvasItem.z_index.
	# Keep the visible front paper last so its buttons receive clicks.
	$PaperStack.move_child(next_front, $PaperStack.get_child_count() - 1)
	var tween := create_tween().set_parallel(true)

	for index in papers.size():
		var paper: TextureRect = papers[index]
		var target_position: Vector2
		var target_rotation: float
		var target_color: Color
		if index == target_index:
			target_position = FRONT_POSITION
			target_rotation = 0.0
			target_color = Color.WHITE
			paper.z_index = papers.size()
			paper.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			var slot := posmod(index - target_index - 1, papers.size())
			target_position = BACK_POSITIONS[slot]
			target_rotation = BACK_ROTATIONS[slot]
			target_color = BACK_COLORS[slot]
			paper.z_index = slot + 1
			paper.mouse_filter = Control.MOUSE_FILTER_STOP
		tween.tween_property(paper, "position", target_position, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(paper, "rotation", target_rotation, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(paper, "modulate", target_color, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	await tween.finished
	page_index = target_index
	content.reparent(next_front, false)
	content.position = Vector2(60.0, 70.0)
	update_page_content()
	content.show()
	is_turning = false


func handle_paper_click(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and index != page_index:
		UiSounds.play_click()
		turn_page(index - page_index)


func update_page_content() -> void:
	title_label.text = PAGE_TITLES[page_index]
	subtitle_label.text = PAGE_SUBTITLES[page_index]
	page_number.text = "%d / %d" % [page_index + 1, papers.size()]
	previous_button.disabled = page_index == 0
	next_button.disabled = page_index == papers.size() - 1
	var is_audio_page := page_index == 0
	volume_label.visible = is_audio_page
	volume_slider.visible = is_audio_page
	volume_value.visible = is_audio_page
	var is_debug_page := page_index == PAGE_TITLES.size() - 1
	page_body.visible = not is_audio_page and not is_debug_page
	debug_hint.visible = is_debug_page
	debug_input.visible = is_debug_page
	debug_run_button.visible = is_debug_page
	debug_feedback.visible = is_debug_page
	if not is_audio_page:
		page_body.text = PAGE_TEXTS[page_index]
	if is_debug_page:
		debug_input.grab_focus()


func execute_debug_command() -> void:
	var command := debug_input.text.strip_edges()
	var age_pattern := RegEx.create_from_string("^/age\\s+([0-9]+)$")
	var matched := age_pattern.search(command)
	if matched == null:
		debug_feedback.text = "命令格式：/age 10"
		return
	var age := int(matched.get_string(1))
	if age < RoundCalendar.START_AGE or age > 99:
		debug_feedback.text = "请输入 4～99 岁。"
		return
	if SceneFade.curtain.visible:
		return
	PlayerState.reset()
	StudyProgress.reset()
	SaveManager.start_new_game()
	PlayerState.player_name = "default"
	PlayerState.round_number = RoundCalendar.first_round_at_age(age)
	PlayerState.school_intro_seen = age >= RoundCalendar.SCHOOL_AGE
	SceneFade.change_to("res://scenes/bedroom.tscn")


func set_master_volume(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus, value <= 0.0)
	if value > 0.0:
		AudioServer.set_bus_volume_db(master_bus, linear_to_db(value / 100.0))
	update_volume_label(value)


func update_volume_label(value: float) -> void:
	volume_value.text = "%d%%" % roundi(value)


func close_settings() -> void:
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close_settings()
		KEY_LEFT:
			get_viewport().set_input_as_handled()
			turn_page(-1)
		KEY_RIGHT:
			get_viewport().set_input_as_handled()
			turn_page(1)
