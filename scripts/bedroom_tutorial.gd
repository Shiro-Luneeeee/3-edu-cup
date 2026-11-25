extends Control

signal finished

const CARD_SIZE := Vector2(500, 246)
const DIM_COLOR := Color(0.12, 0.08, 0.20, 0.70)
const SPOTLIGHT_SHADER := preload("res://shaders/tutorial_spotlight.gdshader")
const STEPS := [
	{"target": "RoundBoard", "title": "第一页 · 岁月", "body": "右上角的年岁，是这段旅程的页码。走过一回合，日历便向前翻；有些故事，只在某个年纪与季节开花。"},
	{"target": "PlayerHud/EnergyBar", "title": "体力 · 今天能走多远", "body": "头顶的体力，是今天可以花费的力气。学习、游玩与行动会消耗它；新的一回合来到时，你也能重新整装出发。"},
	{"target": "stat:0", "title": "智力 · 解开世界的线", "body": "智力像一盏慢慢亮起的灯。学习数学、体验一些游戏，都能让思考成长；积累到新等级时，还会迎来一份成长的礼物。"},
	{"target": "stat:1", "title": "情商 · 听见人心的雨", "body": "情商是读懂言外之意的温柔。语文与某些游戏会为它添上一笔；它也会逐级成长，带来新的奖励。"},
	{"target": "stat:2", "title": "体魄 · 把路走得更远", "body": "体魄记得每一次奔跑与坚持。运动、游玩都能让它变得结实；当积累跨过一级，也会有新的馈赠。"},
	{"target": "BookshelfButton", "title": "书架 · 把日子读成光", "body": "从书架走进学习。语文滋养情商，数学磨亮智力，英语积攒升级点；每一页都要花些体力，却会在往后的回合留下回响。"},
	{"target": "GamepadButton", "title": "游戏机 · 在快乐里成长", "body": "这里可以购买并游玩收藏的游戏。不同游戏会带来不同的成长；玩得越多，游戏审美也会慢慢积满，最终拓宽体力的上限。"},
	{"target": "NotebookButton", "title": "笔记本 · 整理手中的牌", "body": "卡牌是牌局里的句子，升级点能替它们改写笔画。组好卡组后，来这里强化卡牌，再带着它们走向下一场对局。"},
	{"target": "PhoneButton", "title": "手机 · 世界的另一扇窗", "body": "桌上的手机连着卧室以外的生活。地图、社交、商店、画廊与电台，都在这一方小小的屏幕里。"},
	{"target": "PhoneOverlay/PhoneImage/AppRow/Map", "title": "地图 · 去见沿途的风", "body": "地图会带你去学校、公园与街角。看看头像落在哪里，也许某个人、某段故事，正在那里等你。"},
	{"target": "PhoneOverlay/PhoneImage/AppRow/Chat", "title": "社交 · 给相遇留一页", "body": "认识的人会慢慢走进好友列表。你可以在这里回望关系、与他们自由对话；新的剧情仍要在相遇的地方亲自经历。"},
	{"target": "PhoneOverlay/PhoneImage/SecondAppRow/Shop", "title": "金钱与商店", "body": "开局金钱为 0，之后每轮开始获得 10 金钱。通过考试时，进度比目标多超过 20%，今后每轮收入 +1。超过 50% 则 +2。不同考试的奖励可以累加。"},
	{"target": "PhoneOverlay/PhoneImage/AppRow/Gallery", "title": "画廊 · 留住路过的光", "body": "有些画面值得停下脚步再看一眼。画廊收着旅途中的影像，想念的时候，随时可以回来翻阅。"},
	{"target": "ClockButton", "title": "时钟 · 让下一页开始", "body": "当你准备好，就轻触时钟。有牌局的回合，它会带你入场；平静的回合，它会陪你翻向下一季。"},
	{"target": "ExitButton", "title": "归途 · 把今天收好", "body": "左下角的箭头通往存档页。离开前，把今天写进存档；下次回来，故事便能从这一页继续。"},
]

var bedroom: Control
var step_index := 0
var dimmer: ColorRect
var dim_material: ShaderMaterial
var outline: Panel
var card: Panel
var title_label: Label
var body_label: Label
var counter_label: Label
var previous_button: Button
var next_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 40
	dimmer = ColorRect.new()
	dimmer.color = DIM_COLOR
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim_material = ShaderMaterial.new()
	dim_material.shader = SPOTLIGHT_SHADER
	dimmer.material = dim_material
	add_child(dimmer)
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	outline = Panel.new()
	outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color.TRANSPARENT
	outline_style.border_color = Color("ffe6b8")
	outline_style.set_border_width_all(3)
	outline_style.set_corner_radius_all(16)
	outline_style.shadow_color = Color(1.0, 0.79, 0.63, 0.5)
	outline_style.shadow_size = 8
	outline.add_theme_stylebox_override("panel", outline_style)
	add_child(outline)
	card = Panel.new()
	card.size = CARD_SIZE
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("fff2e2")
	paper.border_color = Color("e4b5ad")
	paper.set_border_width_all(2)
	paper.set_corner_radius_all(22)
	paper.shadow_color = Color(0.12, 0.08, 0.20, 0.48)
	paper.shadow_size = 12
	paper.shadow_offset = Vector2(5, 7)
	card.add_theme_stylebox_override("panel", paper)
	add_child(card)
	title_label = make_label(30, Color("684574"), Vector2(26, 20), Vector2(339, 44))
	card.add_child(title_label)
	body_label = make_label(20, Color("715d76"), Vector2(28, 74), Vector2(444, 111))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	card.add_child(body_label)
	counter_label = make_label(17, Color("987c92"), Vector2(28, 204), Vector2(90, 26))
	card.add_child(counter_label)
	previous_button = make_button("上一页", Vector2(225, 195), Vector2(110, 38))
	previous_button.pressed.connect(go_previous)
	card.add_child(previous_button)
	next_button = make_button("继续", Vector2(347, 195), Vector2(127, 38))
	next_button.pressed.connect(go_next)
	card.add_child(next_button)
	var skip := make_button("跳过引导", Vector2(365, 27), Vector2(109, 31))
	skip.add_theme_font_size_override("font_size", 16)
	skip.pressed.connect(close_tutorial)
	card.add_child(skip)
	resized.connect(show_step)
	call_deferred("show_step")


func make_label(font_size: int, color: Color, at: Vector2, dimensions: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func make_button(caption: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = caption
	button.position = at
	button.size = dimensions
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("684574"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("ffe8db")
	style.border_color = Color("dfb2b0")
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("fff8ec")
	button.add_theme_stylebox_override("hover", hover)
	return button


func show_step() -> void:
	if not is_instance_valid(bedroom) or size.x <= 0.0 or size.y <= 0.0:
		return
	var step: Dictionary = STEPS[step_index]
	var target_path: String = step["target"]
	var phone: Control = bedroom.get_node("PhoneOverlay")
	phone.visible = target_path.begins_with("PhoneOverlay/")
	title_label.text = step["title"]
	body_label.text = step["body"]
	counter_label.text = "%02d / %02d" % [step_index + 1, STEPS.size()]
	previous_button.disabled = step_index == 0
	next_button.text = "走进故事" if step_index == STEPS.size() - 1 else "继续"
	if phone.visible:
		# Container children receive their final positions after the phone becomes visible.
		outline.hide()
		dim_material.set_shader_parameter("hole_rect", Vector4(-1.0, -1.0, -1.0, -1.0))
		var requested_step := step_index
		await get_tree().process_frame
		if not is_inside_tree() or requested_step != step_index:
			return
	update_spotlight()
	outline.show()


func update_spotlight() -> void:
	var step: Dictionary = STEPS[step_index]
	var target_path: String = step["target"]
	var target_rect: Rect2
	if target_path.begins_with("stat:"):
		var board := bedroom.get_node("PlayerHud/PointBoard") as TextureRect
		var row_centers := [279.0, 446.0, 615.0]
		var row_index := int(target_path.get_slice(":", 1))
		var board_rect := board.get_global_rect()
		var row_height := board_rect.size.y * 0.22
		target_rect = Rect2(board_rect.position + Vector2(0, board_rect.size.y * row_centers[row_index] / 887.0 - row_height * 0.5), Vector2(board_rect.size.x, row_height))
	else:
		var target := bedroom.get_node_or_null(target_path) as Control
		if target == null:
			return
		target_rect = target.get_global_rect()
	var top_left := get_global_transform().affine_inverse() * target_rect.position
	var bottom_right := get_global_transform().affine_inverse() * target_rect.end
	var expanded := Rect2(top_left, bottom_right - top_left).grow(10.0)
	var left := floorf(clampf(expanded.position.x, 0.0, size.x))
	var top := floorf(clampf(expanded.position.y, 0.0, size.y))
	var right := ceilf(clampf(expanded.end.x, 0.0, size.x))
	var bottom := ceilf(clampf(expanded.end.y, 0.0, size.y))
	var hole := Rect2(left, top, right - left, bottom - top)
	dim_material.set_shader_parameter("hole_rect", Vector4(left / size.x, top / size.y, right / size.x, bottom / size.y))
	outline.position = hole.position
	outline.size = hole.size
	var card_x := size.x - CARD_SIZE.x - 20.0 if hole.get_center().x < size.x * 0.5 else 20.0
	var card_y := size.y - CARD_SIZE.y - 20.0 if hole.get_center().y < size.y * 0.55 else 20.0
	card.position = Vector2(clampf(card_x, 8.0, size.x - CARD_SIZE.x - 8.0), clampf(card_y, 8.0, size.y - CARD_SIZE.y - 8.0))


func go_previous() -> void:
	if step_index > 0:
		step_index -= 1
		show_step()


func go_next() -> void:
	if step_index == STEPS.size() - 1:
		close_tutorial()
	else:
		step_index += 1
		show_step()


func close_tutorial() -> void:
	bedroom.get_node("PhoneOverlay").hide()
	finished.emit()
	queue_free()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_tutorial()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		go_next()
