extends Control

signal completed

enum Speaker { NARRATOR, PLAYER, YUE }

const RoundCalendar := preload("res://round_calendar.gd")
const YUE_NAME := "月侧阳奈里"
const PORTRAIT_SHEET := preload("res://images/character/yue_age_portraits.jpg")
const PORTRAIT_AGES := [4, 7, 13, 16, 19]
const PORTRAIT_REGIONS := [
	Rect2(12, 138, 210, 219),
	Rect2(253, 64, 210, 257),
	Rect2(489, 32, 224, 303),
	Rect2(743, 2, 227, 277),
	Rect2(985, 0, 253, 308),
]
const LISTENING_TINT := Color(0.60, 0.57, 0.64)
const BACKGROUNDS := {
	"park": "res://images/park.png",
	"ants": "res://images/park_meeting/ants.png",
	"pond": "res://images/park_meeting/pond.png",
}
const LINES := [
	{"text": "小区附近的公园，一直是我游玩的天地。", "background": "park"},
	{"text": "但真要说起来，我鲜少在这附近见过同龄的玩伴"},
	{"text": "虽说在疯玩后不免寂寞，但这一片万物竞发、勃勃生机的自然境界，也确实令我心驰神往。"},
	{"text": "那一天——原本对我再普通不过，没有伏笔，没有铺垫，但它就是突兀地\n成为我命中注定的一天", "background": "ants"},
	{"speaker": Speaker.YUE, "text": "你好呀，你也是来这里看鱼的吗？"},
	{"text": "一个和我年纪相仿的女孩，轻轻拍了拍正目不转睛盯着蚂蚁搬家的我"},
	{"speaker": Speaker.PLAYER, "text": "鱼？那有什么好看的，我喜欢蚂蚁。妈妈说，它们都是很勤快的工人"},
	{"speaker": Speaker.YUE, "text": "不要，蚂蚁这种小虫子好恶心的，我们还是去看鱼吧。"},
	{"text": "说着，连名字都还未知晓的女孩自顾自地把我拉到了不远处的小池塘", "background": "pond"},
	{"speaker": Speaker.PLAYER, "text": "等一下，妈妈说过，水边很危险的！"},
	{"speaker": Speaker.YUE, "text": "哦，我知道了，原来你是胆小鬼啊～"},
	{"speaker": Speaker.PLAYER, "text": "我，我才不是胆小鬼呢"},
	{"text": "像是想证明自己一样，我又向池水进了一步，但水边的泥土到底是有些湿润——"},
	{"speaker": Speaker.PLAYER, "text": "哇——", "shake": true},
	{"text": "我一脚踏空，差点掉进水里"},
	{"speaker": Speaker.YUE, "text": "危险——"},
	{"text": "好在女孩一把拉住了我，再加上我自己拼命维持平衡，最终我得以在岸上站稳"},
	{"speaker": Speaker.YUE, "text": "对、对不起，我不该强行拉你来的，还叫你胆小鬼"},
	{"text": "女孩赶忙向我道歉，但我的视线却落在了池塘里被我惊动的那些的鱼"},
	{"text": "先前不怎么游动的鱼，此刻在水中四处游动着，不时还激起一圈水波"},
	{"text": "这时我才明白，身侧的女孩为何这样执着于鱼了"},
	{"speaker": Speaker.YUE, "text": "啊——"},
	{"text": "注意到我的眼神，女孩得意地扬起眉毛，并抛了一大把鱼饵料"},
	{"text": "水里的鱼游得更欢了，这时我注意到，在这些不知名的鱼里，还混着几只大红色的金鱼"},
	{"speaker": Speaker.PLAYER, "text": "确实很好看呢"},
	{"speaker": Speaker.YUE, "text": "是吧，以后我们天天一起来看吧"},
	{"speaker": Speaker.PLAYER, "text": "好啊"},
	{"text": "因为确实被这些灵动的小生命吸引了，我没怎么推脱。"},
	{"text": "听了我的话，女孩伸出自己的右手"},
	{"speaker": Speaker.YUE, "text": "来，我们拉钩"},
	{"speaker": Speaker.PLAYER, "text": "可我连你的名字都不知道"},
	{"speaker": Speaker.YUE, "text": "我叫月侧阳奈里", "reveal_name": true},
	{"speaker": Speaker.PLAYER, "text": "我叫 /name"},
	{"text": "说着，我拉住了眼前少女的手。"},
]

@onready var art: TextureRect = %Background
@onready var yue_portrait: TextureRect = %YuePortrait
@onready var dialogue_box: PanelContainer = $DialogueBox
@onready var name_tag: PanelContainer = %NameTag
@onready var speaker_name: Label = %Speaker
@onready var dialogue: Label = %Dialogue
@onready var next_button: Button = %Next

var line_index := -1
var yue_introduced := false


func _ready() -> void:
	yue_portrait.texture = portrait_for_age(RoundCalendar.age(PlayerState.round_number))
	resized.connect(place_portrait)
	dialogue_box.item_rect_changed.connect(place_portrait)
	place_portrait()
	next_button.pressed.connect(advance)
	advance()


static func portrait_for_age(age: int) -> AtlasTexture:
	var portrait := AtlasTexture.new()
	portrait.atlas = PORTRAIT_SHEET
	portrait.filter_clip = true
	var index := maxi(0, PORTRAIT_AGES.bsearch(age, false) - 1)
	portrait.region = PORTRAIT_REGIONS[index]
	return portrait


func place_portrait() -> void:
	var frame_size := yue_portrait.texture.get_size()
	var bottom := dialogue_box.position.y
	var height_limit := maxf(0.0, minf(size.y * 0.43, bottom - 12.0))
	var factor := minf(size.x * 0.34 / frame_size.x, height_limit / frame_size.y)
	yue_portrait.size = frame_size * factor
	yue_portrait.position = Vector2(size.x * 0.77, bottom + 2.0) - yue_portrait.size * Vector2(0.5, 1.0)


func advance() -> void:
	if line_index >= LINES.size():
		return
	line_index += 1
	if line_index == LINES.size():
		completed.emit()
		return
	var line: Dictionary = LINES[line_index]
	if line.has("background"):
		art.texture = load(BACKGROUNDS[line["background"]]) as Texture2D
	var speaker: int = line.get("speaker", Speaker.NARRATOR)
	if speaker == Speaker.YUE:
		yue_portrait.show()
	yue_portrait.modulate = Color.WHITE if speaker == Speaker.YUE else LISTENING_TINT
	yue_introduced = yue_introduced or line.get("reveal_name", false)
	match speaker:
		Speaker.PLAYER: speaker_name.text = PlayerState.player_name
		Speaker.YUE: speaker_name.text = YUE_NAME if yue_introduced else "女孩"
		_: speaker_name.text = ""
	name_tag.visible = not speaker_name.text.is_empty()
	dialogue.text = str(line["text"]).replace("/name", PlayerState.player_name)
	next_button.text = "回到公园  ›" if line_index == LINES.size() - 1 else "继续  ›"
	if line.get("shake", false):
		shake_background()


func shake_background() -> void:
	art.pivot_offset = art.size * 0.5
	art.scale = Vector2.ONE * 1.035
	var strength := minf(12.0, art.size.x * 0.01)
	var shake := create_tween()
	shake.tween_property(art, "position", Vector2(-strength, -4), 0.045)
	shake.tween_property(art, "position", Vector2(strength, 3), 0.055)
	shake.tween_property(art, "position", Vector2(-strength * 0.45, 0), 0.045)
	shake.tween_property(art, "position", Vector2.ZERO, 0.085)
	shake.tween_property(art, "scale", Vector2.ONE, 0.10)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		advance()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_echo() and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select")):
		get_viewport().set_input_as_handled()
		advance()
