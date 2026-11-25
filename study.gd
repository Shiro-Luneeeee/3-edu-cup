extends ColorRect

const SUBJECT_NAMES := ["语文", "数学", "英语"]
const SUBJECT_REWARDS := ["情商经验", "智商经验", "升级点"]
const FEELINGS := [
	[
		"语文吗？修辞手法、表现手法……这些就叫语文，是吗？",
		"原来同一句话，也可以藏着不一样的天气。",
		"有些心情说不明白，诗却替我说出来了。",
		"好喜欢朦胧诗派的味道啊。像隔着雾，认出自己的心事。",
		"今天读到一句话，突然想起了一个很久没见的人。",
		"以前总问作者想表达什么，现在也想问问自己读到了什么。",
		"文字真奇怪，明明没有声音，却能在心里响很久。",
		"开始舍不得把每一朵花，都拆成一道阅读理解了。",
		"写了一整页，又删到只剩一句。好像终于接近想说的话了。",
		"读别人的故事，偶尔会撞见那个还没学会告别的自己。",
		"或许学语文，就是慢慢学会，怎样认真地看见一个人。"
	],
	[
		"数学吗？题目里的每个字我都认识，连起来怎么就不认识我了：）",
		"终于算对了！先别问原理，让我高兴一小会儿。",
		"原来辅助线不是凭空出现的……虽然我还是画不出来。",
		"把乱七八糟的条件接起来，居然有一点拼图的快乐。",
		"欧拉和拉格朗日的脑袋，到底是怎么长的啊。",
		"证明到最后一行的时候，有种雨终于停了的感觉。",
		"今天的直觉竟然是对的。等等，我是不是有点飘了。",
		"完了，手痒了，想徒手证明黎曼猜想了 OMO",
		"冷静，先把刚才漏掉的定义域补上。",
		"以前觉得公式很冷，现在觉得它们只是把浪漫藏得太深。",
		"越学越知道自己不会什么。但这次，好像没那么害怕了。"
	],
	[
		"英语吗？可是我哪怕学了今天的英语，也读不了莎士比亚的原文啊 QAQ",
		"这个单词昨天才见过！它怎么又装作不认识我了。",
		"听懂了一小句，像在陌生的城市里认出了一盏灯。",
		"终于不用在脑袋里逐字翻译了……偶尔，真的只是偶尔。",
		"歌词原来是这个意思。突然觉得那首歌更难过了。",
		"同一种想念，换一种语言，竟然会长出不同的形状。",
		"今天想试着不看字幕。好吧，先从三十秒开始。",
		"读到一句漂亮的英文，舍不得立刻把它翻译过来。",
		"莎士比亚还是有点远，但路边的故事已经能读懂一些了。",
		"开始听得见语气里那些小小的停顿，比标准答案还生动。",
		"原来多学一种语言，是给世界多开了一扇窗。"
	]
]
const SMALL_DISCOVERIES := [
	"你感觉自己对语文，似乎有了一点不一样的理解。\n有些还说不清的东西，正轻轻落在心里。",
	"你感到头颅里这个正在蒸馏欧拉、拉格朗日等超级大模型的小参数模型，又迭代了似乎没用的一代：）",
	"你又捡起了几个词，暂时还拼不出莎士比亚的月亮。\n不过，下次遇见它们，也许就能认出来了 QAQ"
]

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
var subject_scroll := ScrollContainer.new()
var subject_list := VBoxContainer.new()
var thought := Label.new()
var action_thoughts: Dictionary[int, String] = {}


func _ready() -> void:
	create_subject_list()
	create_thought()
	close_button.pressed.connect(close_study)
	confirm_button.add_to_group("study_action_button")
	confirm_button.pressed.connect(perform_selected_action)
	for index in subject_buttons.size():
		subject_buttons[index].add_to_group("study_subject_button")
		subject_buttons[index].pressed.connect(select_subject.bind(index))
	StudyProgress.changed.connect(update_progress)
	PlayerState.changed.connect(update_action_availability)
	resized.connect(update_layout)
	update_layout()
	select_subject(selected_subject)
	update_action_availability()


func create_subject_list() -> void:
	subject_scroll.name = "SubjectScroll"
	board.add_child(subject_scroll)
	subject_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	subject_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	subject_scroll.add_child(subject_list)
	subject_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for button in subject_buttons:
		button.reparent(subject_list)
		button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func create_thought() -> void:
	thought.name = "InnerVoice"
	thought.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	thought.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	thought.add_theme_color_override("font_color", Color("594375"))
	thought.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(thought)


func update_layout() -> void:
	var texture_size := board.texture.get_size()
	var board_scale := minf(size.x / texture_size.x, size.y / texture_size.y)
	board.size = texture_size * board_scale
	board.position = (size - board.size) * 0.5
	subject_scroll.position = board.size * Vector2(0.10, 0.21)
	subject_scroll.size = board.size * Vector2(0.32, 0.64)
	var subject_gap := maxi(2, roundi(8.0 * board_scale))
	subject_list.add_theme_constant_override("separation", subject_gap)
	var row_height := floorf((subject_scroll.size.y - subject_gap * (subject_buttons.size() - 1)) / subject_buttons.size())
	for button in subject_buttons:
		button.custom_minimum_size = Vector2(0, row_height)
	thought.position = board.size * Vector2(0.54, 0.335)
	thought.size = board.size * Vector2(0.395, 0.215)
	thought.add_theme_font_size_override("font_size", maxi(1, roundi(28.0 * board_scale)))
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
	update_thought()


func update_thought() -> void:
	if action_thoughts.has(selected_subject):
		thought.text = action_thoughts[selected_subject]
		return
	var level := StudyProgress.get_level(selected_subject)
	var lines: Array = FEELINGS[selected_subject]
	thought.text = "「%s」" % lines[level] if level < lines.size() else "「%s」\n\n学到第 %d 级，再读这一句，心里又多了一层回声。" % [lines[level % lines.size()], level]


func perform_selected_action() -> void:
	var old_level := StudyProgress.get_level(selected_subject)
	if StudyProgress.perform_action(selected_subject):
		if StudyProgress.get_level(selected_subject) > old_level:
			action_thoughts.erase(selected_subject)
		else:
			action_thoughts[selected_subject] = SMALL_DISCOVERIES[selected_subject]
		update_thought()
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
