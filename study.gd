extends ColorRect

const SUBJECT_NAMES := ["语文", "数学", "英语"]
const SUBJECT_REWARDS := ["情商经验", "智商经验", "升级点"]

@onready var board: TextureRect = $StudyBoard
@onready var close_button: Button = $StudyBoard/CloseButton
@onready var confirm_button: TextureButton = $StudyBoard/ConfirmButton
@onready var subject_buttons: Array[TextureButton] = [$StudyBoard/Chinese, $StudyBoard/Math, $StudyBoard/English]
@onready var progress_material := $StudyBoard/ProgressBar.material as ShaderMaterial
@onready var subject_name: Label = $StudyBoard/SubjectName
@onready var level_value: Label = $StudyBoard/LevelValue
@onready var experience_value: Label = $StudyBoard/ExperienceValue
@onready var round_reward_label: Label = $StudyBoard/RoundReward
@onready var reward_label: Label = $StudyBoard/ActionReward
@onready var energy_cost_label: Label = $StudyBoard/ActionEnergyCost

var selected_subject := StudyProgress.Subject.CHINESE


func _ready() -> void:
	close_button.pressed.connect(close_study)
	confirm_button.pressed.connect(perform_selected_action)
	for index in subject_buttons.size():
		subject_buttons[index].pressed.connect(select_subject.bind(index))
	StudyProgress.changed.connect(update_progress)
	PlayerState.changed.connect(update_action_availability)
	resized.connect(update_layout)
	update_layout()
	select_subject(selected_subject)
	update_action_availability()


func update_layout() -> void:
	var texture_size := board.texture.get_size()
	var board_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	board.size = texture_size * board_scale
	board.position = (size - board.size) * 0.5
	subject_name.add_theme_font_size_override("font_size", maxi(1, roundi(36.0 * board_scale)))
	var value_font_size := maxi(1, roundi(34.0 * board_scale))
	level_value.add_theme_font_size_override("font_size", value_font_size)
	experience_value.add_theme_font_size_override("font_size", value_font_size)
	var action_font_size := maxi(1, roundi(29.0 * board_scale))
	round_reward_label.add_theme_font_size_override("font_size", action_font_size)
	reward_label.add_theme_font_size_override("font_size", action_font_size)
	energy_cost_label.add_theme_font_size_override("font_size", action_font_size)


func select_subject(subject: StudyProgress.Subject) -> void:
	selected_subject = subject
	for index in subject_buttons.size():
		subject_buttons[index].modulate = Color.WHITE if index == subject else Color("d9ccde")
	update_progress()
	update_action_reward()


func update_progress() -> void:
	var progress := StudyProgress.get_progress(selected_subject)
	var required := StudyProgress.required_experience(progress.x)
	subject_name.text = SUBJECT_NAMES[selected_subject]
	level_value.text = "Lv. %d" % progress.x
	experience_value.text = "%d / %d" % [progress.y, required]
	progress_material.set_shader_parameter("fill_ratio", float(progress.y) / required)
	round_reward_label.text = "每回合  %s +%d" % [SUBJECT_REWARDS[selected_subject], progress.x]


func perform_selected_action() -> void:
	if StudyProgress.perform_action(selected_subject):
		update_action_reward(true)


func update_action_reward(completed: bool = false) -> void:
	var prefix := "已完成   " if completed else ""
	reward_label.text = "%s%s +%d   ·   经验 +%d" % [
		prefix, SUBJECT_REWARDS[selected_subject], StudyProgress.ACTION_REWARD, StudyProgress.ACTION_EXPERIENCE
	]


func update_action_availability() -> void:
	var cost := StudyProgress.ACTION_ENERGY_COST
	var energy := PlayerState.current_energy
	var can_act := energy >= cost
	confirm_button.disabled = not can_act
	confirm_button.modulate = Color.WHITE if can_act else Color("aaa1ae")
	var prefix := "精力" if can_act else "精力不足"
	energy_cost_label.text = "%s %s   ·   消耗 %d" % [prefix, PlayerState.energy_text(), cost]
	energy_cost_label.add_theme_color_override("font_color", Color("594375") if can_act else Color("963e51"))


func close_study() -> void:
	SceneFade.play_action(queue_free, -1.0)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_study()
