extends "res://scripts/story_dialogue.gd"

enum Speaker { NARRATOR, PLAYER, YUE }

const SocialCharacters := preload("res://scripts/social_characters.gd")
const YuePortraits := preload("res://scripts/yue_portraits.gd")
const BACKGROUNDS := {
	"park": "res://images/park.png",
	"ants": "res://images/park_meeting/ants.png",
	"greeting": "res://images/park_meeting/greeting.png",
	"pond": "res://images/park_meeting/pond.png",
	"promise": "res://images/park_meeting/promise.png",
}
const LINES := [
	{"text": "小区附近的公园，一直是我游玩的天地。", "background": "park"},
	{"text": "但真要说起来，我鲜少在这附近见过同龄的玩伴"},
	{"text": "虽说在疯玩后不免寂寞，但这一片万物竞发、勃勃生机的自然境界，也确实令我心驰神往。"},
	{"text": "那一天——原本对我再普通不过，没有伏笔，没有铺垫，但它就是突兀地\n成为我命中注定的一天", "background": "ants"},
	{"speaker": Speaker.YUE, "text": "你好呀，你也是来这里看鱼的吗？"},
	{"text": "一个和我年纪相仿的女孩，轻轻拍了拍正目不转睛盯着蚂蚁搬家的我", "background": "greeting"},
	{"speaker": Speaker.PLAYER, "text": "鱼？那有什么好看的，我喜欢蚂蚁。妈妈说，它们都是很勤快的工人"},
	{"speaker": Speaker.YUE, "text": "不要，蚂蚁这种小虫子好恶心的，我们还是去看鱼吧。"},
	{"text": "说着，连名字都还未知晓的女孩自顾自地把我拉到了不远处的小池塘", "background": "pond"},
	{"speaker": Speaker.PLAYER, "text": "等一下，妈妈说过，水边很危险的！"},
	{"speaker": Speaker.YUE, "text": "哦，我知道了，原来你是胆小鬼啊～"},
	{"speaker": Speaker.PLAYER, "text": "我，我才不是胆小鬼呢"},
	{"text": "像是想证明自己一样，我又向池水进了一步，但水边的泥土到底是有些湿润——"},
	{"speaker": Speaker.PLAYER, "text": "哇——", "shake": true, "expression": YuePortraits.Mood.WORRIED},
	{"text": "我一脚踏空，差点掉进水里"},
	{"speaker": Speaker.YUE, "text": "危险——"},
	{"text": "好在女孩一把拉住了我，再加上我自己拼命维持平衡，最终我得以在岸上站稳"},
	{"speaker": Speaker.YUE, "text": "对、对不起，我不该强行拉你来的，还叫你胆小鬼"},
	{"text": "女孩赶忙向我道歉，但我的视线却落在了池塘里被我惊动的那些的鱼"},
	{"text": "先前不怎么游动的鱼，此刻在水中四处游动着，不时还激起一圈水波"},
	{"text": "这时我才明白，身侧的女孩为何这样执着于鱼了"},
	{"speaker": Speaker.YUE, "text": "啊——", "expression": YuePortraits.Mood.CHEERFUL},
	{"text": "注意到我的眼神，女孩得意地扬起眉毛，并抛了一大把鱼饵料"},
	{"text": "水里的鱼游得更欢了，这时我注意到，在这些不知名的鱼里，还混着几只大红色的金鱼"},
	{"speaker": Speaker.PLAYER, "text": "确实很好看呢"},
	{"speaker": Speaker.YUE, "text": "是吧，以后我们天天一起来看吧"},
	{"speaker": Speaker.PLAYER, "text": "好啊"},
	{"text": "因为确实被这些灵动的小生命吸引了，我没怎么推脱。"},
	{"text": "听了我的话，女孩伸出自己的右手", "background": "promise"},
	{"speaker": Speaker.YUE, "text": "来，我们拉钩"},
	{"speaker": Speaker.PLAYER, "text": "可我连你的名字都不知道"},
	{"speaker": Speaker.YUE, "text": "我叫月侧阳奈里", "reveal_name": true},
	{"speaker": Speaker.PLAYER, "text": "我叫 /name"},
	{"text": "说着，我拉住了眼前少女的手。"},
]

var yue_introduced := false


func _ready() -> void:
	set_portrait_expression(YuePortraits.Mood.CHEERFUL)
	super._ready()


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "回到公园  ›"


func set_portrait_expression(expression: YuePortraits.Mood) -> void:
	YuePortraits.show_on(yue_portrait, SocialCharacters.FIRST_MEETING_AGE, expression)
	place_portrait()


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		var location: String = line["background"]
		show_yue_background(load(BACKGROUNDS[location]) as Texture2D, location == "pond")
	if line.has("expression"):
		set_portrait_expression(line["expression"])
	var speaker: int = line.get("speaker", Speaker.NARRATOR)
	yue_portrait.modulate = Color.WHITE if speaker == Speaker.YUE else LISTENING_TINT
	yue_introduced = yue_introduced or line.get("reveal_name", false)
	if line.get("shake", false):
		shake_stage()
	match speaker:
		Speaker.PLAYER: return PlayerState.player_name
		Speaker.YUE: return SocialCharacters.YUE if yue_introduced else "女孩"
	return ""
