extends Control

# Tagore, Stray Birds; Chinese wording supplied by the user.
const PAGES := [
	"无论你从怎样的昨日走来。\n\n是衣襟沾满风尘，还是心里落着漫长的雨；是曾被掌声簇拥，还是在浮华里弄丢了自己。\n\n是始终站在人群之外，还是随潮水漂流了很远——\n\n此刻，都请在这里，轻轻歇一歇。",
	"夏日的风翻过花海，光落在尚未写下的名字上。\n\n你将在这样的一个夏天出生。\n\n从第一声啼哭，到第一次学会告别；从懵懂的相逢，到终于懂得珍惜。\n\n你会与她们同行，走过十八年的晴雨。",
	"那或许是你尚未走完的年岁，或许是你已经离开、却仍在梦里回望的远方。\n\n这一次，愿你不必急着长大。\n\n请好好地爱她们，也请温柔地爱自己。\n\n让那些来不及说出口的话，在这个夏天，慢慢开花。",
	"有一次，我们梦见大家都是不相识的。\n\n我们醒了，却知道我们原是相亲相爱的。\n\n—— 泰戈尔《飞鸟集》\n\n于是，世界又为你留出了一束光。\n\n在故事开始之前，\n请告诉这个夏天，该怎样唤你。"
]

var paper := TextureRect.new()
var heading := Label.new()
var body := RichTextLabel.new()
var name_input := LineEdit.new()
var next_button := Button.new()
var previous_button := Button.new()
var page := 0
var reveal := 0.0
var leaving := false
var opening := true
var confirming := false

func _ready() -> void:
	var background := TextureRect.new()
	background.texture = preload("res://images/summer_birth.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Use the paper interior so its transparent outer border cannot expose the background.
	var paper_source := preload("res://images/aged_blank_a4_paper.png")
	var paper_fill := AtlasTexture.new()
	paper_fill.atlas = paper_source
	paper_fill.region = Rect2(paper_source.get_size() * Vector2(0.07, 0.06), paper_source.get_size() * Vector2(0.86, 0.87))
	paper.texture = paper_fill
	paper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	for item in [heading, body, name_input, next_button, previous_button]:
		paper.add_child(item)
		item.add_theme_color_override("font_color", Color("514d54"))
	heading.text = "写给初生的你"
	body.add_theme_color_override("default_color", Color("514d54"))
	for button in [next_button, previous_button]:
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.add_theme_color_override("font_hover_color", Color("93704e"))
		button.add_theme_color_override("font_pressed_color", Color("514d54"))
		button.add_theme_color_override("font_focus_color", Color("514d54"))
		button.add_theme_color_override("font_disabled_color", Color("9a9185"))
	var underline := StyleBoxFlat.new()
	underline.bg_color = Color.TRANSPARENT
	underline.border_width_bottom = 1
	underline.border_color = Color("847764")
	for state in ["normal", "focus", "read_only"]:
		name_input.add_theme_stylebox_override(state, underline)
	name_input.add_theme_color_override("font_placeholder_color", Color("8a8075"))
	name_input.add_theme_color_override("caret_color", Color("514d54"))
	body.scroll_active = false
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_input.placeholder_text = "在这里写下你的姓名"
	name_input.max_length = 12
	name_input.text_changed.connect(func(value: String) -> void: next_button.disabled = value.strip_edges().is_empty())
	name_input.text_submitted.connect(func(_value: String) -> void: advance())
	next_button.pressed.connect(advance)
	previous_button.text = "上一页"
	previous_button.pressed.connect(go_back)
	resized.connect(layout_page)
	layout_page()
	show_page()
	var music := AudioStreamPlayer.new()
	var track := preload("res://audio/music/Mateus Asato - Goodbye.mp3").duplicate() as AudioStreamMP3
	track.loop = true
	music.stream = track
	music.volume_db = -10.0
	add_child(music)
	music.play()
	var darkness := ColorRect.new()
	darkness.color = Color.BLACK
	darkness.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(darkness)
	darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sunrise := create_tween()
	sunrise.tween_interval(0.6)
	sunrise.tween_property(darkness, "modulate:a", 0.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sunrise.tween_callback(func() -> void: darkness.queue_free(); opening = false)

func layout_page() -> void:
	var factor := minf(size.x / 1152.0, size.y / 648.0)
	paper.size = Vector2(size.x * 0.27 / factor, size.y / factor)
	paper.scale = Vector2.ONE * factor
	paper.position = Vector2(size.x * 0.73, 0.0)
	heading.position = Vector2(33, 48)
	heading.size = Vector2(paper.size.x - 66, 44)
	heading.add_theme_font_size_override("font_size", 24)
	body.position = Vector2(33, 112)
	body.size = Vector2(paper.size.x - 66, paper.size.y - 270)
	body.add_theme_font_size_override("normal_font_size", 17)
	body.add_theme_constant_override("normal_line_separation", 7)
	name_input.position = Vector2(33, paper.size.y - 130)
	name_input.size = Vector2(paper.size.x - 66, 42)
	name_input.add_theme_font_size_override("font_size", 20)
	previous_button.position = Vector2(25, paper.size.y - 65)
	previous_button.size = Vector2(90, 36)
	next_button.position = Vector2(paper.size.x - 160, paper.size.y - 65)
	next_button.size = Vector2(135, 36)

func show_page() -> void:
	body.text = PAGES[page]
	if confirming:
		body.text = "你确定，要叫作「%s」吗？\n\n若心中还有另一声轻轻的回响，也不必急着回答。\n\n这里并非现实，命运尚未落笔。\n\n你还有一次机会，俯身听听心底的风，为初生的自己，拾起一个愿意相伴一生的名字。" % name_input.text.strip_edges()
	reveal = 0.0
	body.visible_characters = 0
	name_input.visible = page == PAGES.size() - 1 and not confirming
	previous_button.visible = page > 0
	previous_button.text = "重新落笔" if confirming else "上一页"
	next_button.text = "就叫这个名字" if confirming else ("写下这个名字" if name_input.visible else "继续阅读  →")
	next_button.disabled = name_input.visible and name_input.text.strip_edges().is_empty()

func go_back() -> void:
	if opening or leaving:
		return
	if confirming:
		confirming = false
	else:
		page = maxi(0, page - 1)
	show_page()
	if name_input.visible:
		name_input.grab_focus()

func _process(delta: float) -> void:
	if opening:
		return
	reveal += delta * 35.0
	body.visible_characters = mini(int(reveal), body.get_total_character_count())

func advance() -> void:
	if leaving or opening:
		return
	if body.visible_characters < body.get_total_character_count():
		reveal = float(body.get_total_character_count())
		body.visible_characters = body.get_total_character_count()
		return
	if page < PAGES.size() - 1:
		page += 1
		show_page()
	elif not name_input.text.strip_edges().is_empty():
		if not confirming:
			confirming = true
			name_input.release_focus()
			show_page()
			return
		leaving = true
		PlayerState.player_name = name_input.text.strip_edges()
		next_button.disabled = true
		SceneFade.change_to("res://bedroom.tscn", 1.0, PlayerState.round_number)
