extends Control

signal closed

const CardCatalog := preload("res://card_catalog.gd")
const SocialCharacters := preload("res://social_characters.gd")
const StoryDialogue := preload("res://story_dialogue.gd")
const FinalExamEnding := preload("res://final_exam_ending.gd")
const StoryCardOffer := preload("res://story_card_offer.gd")
const CARD_OFFER_SCENE := preload("res://story_card_offer.tscn")
const SECTIONS := [
	{
		"label": "主线",
		"chapters": [
			{"title": "小学入学", "scene": preload("res://school_intro.tscn")},
			{"title": "初中开学第一天", "scene": preload("res://middle_school_intro.tscn")},
			{"title": "高中开学第一天", "scene": preload("res://high_school_intro.tscn")},
			{"title": "高考结局", "scene": preload("res://final_exam_ending.tscn")},
		],
	},
	{
		"label": SocialCharacters.YUE,
		"chapters": [
			{"title": "公园初遇", "scene": preload("res://park_meeting.tscn"), "card": CardCatalog.YUE_FIRST_CARD},
			{"title": "池塘边的礼物", "scene": preload("res://yue_goldfish.tscn"), "card": CardCatalog.YUE_GOLDFISH_CARD},
			{"title": "金鱼的告别", "scene": preload("res://yue_farewell.tscn"), "card": CardCatalog.YUE_EMPTY_FISHBOWL_CARD},
			{"title": "晚风里的告白", "scene": preload("res://yue_confession.tscn"), "card": CardCatalog.YUE_OATH_CARD, "confession": true},
			{"title": "高考前的约定", "scene": preload("res://yue_final_promise.tscn"), "card": CardCatalog.YUE_FINAL_PROMISE_CARD},
		],
	},
	{
		"label": SocialCharacters.FUSHIMI,
		"chapters": [
			{"title": "夜姬的钢笔", "scene": preload("res://fushimi_pen_story.tscn"), "card": CardCatalog.FUSHIMI_CARDS_BY_NUMBER[SocialCharacters.FushimiChapter.PEN]},
			{"title": "放学后的补习", "scene": preload("res://fushimi_tutoring.tscn"), "card": CardCatalog.FUSHIMI_CARDS_BY_NUMBER[SocialCharacters.FushimiChapter.TUTORING]},
			{"title": "旧书店的秘密", "scene": preload("res://fushimi_bookshop.tscn"), "card": CardCatalog.FUSHIMI_CARDS_BY_NUMBER[SocialCharacters.FushimiChapter.BOOKSHOP]},
			{"title": "放学后的告白", "scene": preload("res://fushimi_confession.tscn"), "card": CardCatalog.FUSHIMI_CARDS_BY_NUMBER[SocialCharacters.FushimiChapter.CONFESSION], "confession": true},
			{"title": "天台上的约定", "scene": preload("res://fushimi_final_promise.tscn"), "card": CardCatalog.FUSHIMI_CARDS_BY_NUMBER[SocialCharacters.FushimiChapter.FINAL_PROMISE]},
		],
	},
	{
		"label": SocialCharacters.SHIRAKAWA,
		"chapters": [
			{"title": "课间的买刀买马", "scene": preload("res://shirakawa_first_story.tscn")},
			{"title": "小巷里的小毛球", "scene": preload("res://shirakawa_puppy.tscn")},
			{"title": "秋天最后的颜色", "scene": preload("res://shirakawa_osmanthus.tscn")},
			{"title": "教室里的告白", "scene": preload("res://shirakawa_confession.tscn"), "confession": true},
			{"title": "温暖的甜", "scene": preload("res://shirakawa_snow.tscn")},
		],
	},
]

@onready var list_view: ColorRect = $ListView
@onready var panel: PanelContainer = %Panel
@onready var chapters: VBoxContainer = %Chapters
@onready var close_button: Button = %Close

var active_page: Control
var selected_button: Button


func _ready() -> void:
	close_button.pressed.connect(closed.emit)
	resized.connect(fit_panel)
	fit_panel()
	for section: Dictionary in SECTIONS:
		var heading := Label.new()
		heading.text = section["label"]
		heading.theme_type_variation = &"PreviewSection"
		chapters.add_child(heading)
		for chapter: Dictionary in section["chapters"]:
			var choice := Button.new()
			choice.text = chapter["title"]
			choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
			choice.theme_type_variation = &"PreviewChapter"
			choice.custom_minimum_size.y = 38.0
			choice.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			choice.pressed.connect(select_chapter.bind(section["label"], chapter, choice))
			chapters.add_child(choice)
			if selected_button == null:
				selected_button = choice
	selected_button.grab_focus()


func fit_panel() -> void:
	panel.custom_minimum_size = Vector2(minf(540.0, size.x - 32.0), minf(554.0, size.y - 32.0))


func select_chapter(character: String, chapter: Dictionary, choice: Button) -> void:
	selected_button = choice
	if not chapter.get("confession", false):
		play_chapter(character, chapter)
		return
	var confirmation := CARD_OFFER_SCENE.instantiate() as StoryCardOffer
	confirmation.decided.connect(confirm_chapter.bind(character, chapter), CONNECT_ONE_SHOT)
	active_page = confirmation
	add_child(confirmation)
	confirmation.show_confession_confirmation(character, true)


func confirm_chapter(accepted: bool, character: String, chapter: Dictionary) -> void:
	if accepted:
		play_chapter(character, chapter)
	else:
		show_list()


func play_chapter(character: String, chapter: Dictionary) -> void:
	clear_page()
	list_view.hide()
	var scene: PackedScene = chapter["scene"]
	var page := scene.instantiate()
	if page is FinalExamEnding:
		page.preview = true
		page.preview_finished.connect(show_list, CONNECT_ONE_SHOT)
		active_page = page
		add_child(page)
		return
	var card_id: int = chapter.get("card", -1)
	var story := page as StoryDialogue
	story.preview_end_text = "查看专属卡  ›" if card_id >= 0 else "返回剧情列表  ›"
	story.completed.connect(finish_chapter.bind(story, character, card_id), CONNECT_ONE_SHOT)
	active_page = story
	add_child(story)


func finish_chapter(story: StoryDialogue, character: String, card_id: int) -> void:
	if card_id < 0:
		show_list()
		return
	story.dialogue_box.hide()
	var offer := CARD_OFFER_SCENE.instantiate() as StoryCardOffer
	offer.decided.connect(show_list.unbind(1), CONNECT_ONE_SHOT)
	story.add_child(offer)
	offer.show_offer(character, card_id, true)


func clear_page() -> void:
	if is_instance_valid(active_page):
		active_page.hide()
		active_page.queue_free()
		active_page = null


func show_list() -> void:
	clear_page()
	list_view.show()
	selected_button.grab_focus()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.is_echo() and (event.keycode == KEY_I or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		if is_instance_valid(active_page):
			show_list()
		else:
			closed.emit()
