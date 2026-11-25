extends Control

signal preview_finished

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const PAPER_SOURCE := preload("res://images/aged_blank_a4_paper.png")
const CG_IMAGES := [
	preload("res://images/final_exam/Gaokao_POV_01_final_bell.png"),
	preload("res://images/final_exam/Gaokao_POV_02_classroom.png"),
	preload("res://images/final_exam/Gaokao_POV_03_corridor.png"),
	preload("res://images/final_exam/Gaokao_POV_04_gate.png"),
	preload("res://images/final_exam/Gaokao_POV_05_canopy.png"),
]
const CG_TITLES := ["铃声落下", "最后一眼", "长廊有风", "校门之外", "仍是夏天"]
const CG_TEXTS := [
	"最后一声铃响，我放下笔。\n窗外的光落在试卷上，\n那些奔跑过的日子，\n忽然安静了下来。\n\n原来，我们真的走到了这里。",
	"我回头看了一眼教室。\n桌椅还在，夏天还在，\n曾经以为走不完的岁月，\n却已经轻轻翻过最后一页。\n\n谢谢你，陪我写到这里。",
	"走廊尽头有风。\n我听见身旁熟悉的脚步，\n也想起一路上每一次相逢。\n\n我们走过晴雨，走过告别，\n终究仍在彼此的故事里同行。",
	"校门外的人群向前流去。\n我不知道明天会把我们\n带向怎样的远方。\n\n但此刻的笑声与阳光，\n已经足够让我记住这个夏天。",
	"我抬起头，树叶间的光\n像未写完的句子，缓缓流动。\n\n若有一天，我们各自远行，\n也请记得曾经并肩的路。\n\n请允我如夏日般融化，\n把这一刻的温柔留给你。",
]

@onready var story_layer: Control = $StoryLayer
@onready var cg_image: TextureRect = $StoryLayer/CGImage
@onready var story_paper: TextureRect = $StoryLayer/Paper
@onready var title_label: Label = $StoryLayer/Paper/Title
@onready var body_label: Label = $StoryLayer/Paper/Body
@onready var page_label: Label = $StoryLayer/Paper/PageNumber
@onready var credits: Control = $Credits
@onready var credits_paper: TextureRect = $Credits/Paper
@onready var return_button: Button = $Credits/Paper/ReturnButton
@onready var cg_music: AudioStreamPlayer = $CGMusic
@onready var credits_music: AudioStreamPlayer = $CreditsMusic

var preview := false
var page_index := 0
var transitioning := true
var showing_credits := false


func _ready() -> void:
	var paper_fill := AtlasTexture.new()
	paper_fill.atlas = PAPER_SOURCE
	paper_fill.region = Rect2(PAPER_SOURCE.get_size() * Vector2(0.07, 0.06), PAPER_SOURCE.get_size() * Vector2(0.86, 0.87))
	story_paper.texture = paper_fill
	credits_paper.texture = paper_fill
	return_button.text = "返回剧情列表" if preview else "返回标题"
	return_button.pressed.connect(finish_ending)
	set_page(0)
	story_layer.modulate.a = 0.0
	credits.hide()
	var goodbye := cg_music.stream.duplicate() as AudioStreamMP3
	goodbye.loop = true
	cg_music.stream = goodbye
	cg_music.play()
	var welcome := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	welcome.tween_property(story_layer, "modulate:a", 1.0, 1.0)
	await welcome.finished
	transitioning = false


func set_page(index: int) -> void:
	page_index = index
	cg_image.texture = CG_IMAGES[index]
	title_label.text = CG_TITLES[index]
	body_label.text = CG_TEXTS[index]
	page_label.text = "%d / %d   ·   点击或按空格继续" % [index + 1, CG_IMAGES.size()]


func advance() -> void:
	if transitioning or showing_credits:
		return
	transitioning = true
	var fade_out := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_out.tween_property(story_layer, "modulate:a", 0.0, 0.55)
	await fade_out.finished
	if page_index + 1 < CG_IMAGES.size():
		set_page(page_index + 1)
		var fade_in := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_in.tween_property(story_layer, "modulate:a", 1.0, 0.7)
		await fade_in.finished
		transitioning = false
	else:
		show_credits()


func show_credits() -> void:
	showing_credits = true
	story_layer.hide()
	credits.modulate.a = 0.0
	credits.show()
	var otsukare := credits_music.stream.duplicate() as AudioStreamMP3
	otsukare.loop = true
	credits_music.stream = otsukare
	credits_music.volume_db = -60.0
	credits_music.play()
	var transition := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	transition.tween_property(credits, "modulate:a", 1.0, 0.9)
	transition.tween_property(cg_music, "volume_db", -60.0, 1.0)
	transition.tween_property(credits_music, "volume_db", -10.0, 1.0)
	await transition.finished
	cg_music.stop()
	return_button.grab_focus()
	transitioning = false


func _unhandled_input(event: InputEvent) -> void:
	if showing_credits or transitioning:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		advance()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		advance()


func finish_ending() -> void:
	if preview:
		preview_finished.emit()
	else:
		SceneFade.change_to(MAIN_MENU_SCENE)
