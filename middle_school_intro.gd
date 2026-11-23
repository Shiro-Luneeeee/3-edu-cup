extends "res://story_dialogue.gd"

enum YueMood { WAVING, WINKING, LAUGHING, POUTING, SURPRISED, SMILING }
enum FushimiMood { CALM, GREETING, CURIOUS, STERN, AMUSED, SMILING }

const SocialCharacters := preload("res://social_characters.gd")
const YUE_EXPRESSIONS := "res://images/middle_school_intro/yue_expressions.png"
const FUSHIMI_EXPRESSIONS := "res://images/middle_school_intro/fushimi_expressions.png"
const BACKGROUNDS := {
	"gate": "res://images/middle_school_intro/gate.png",
	"roster": "res://images/middle_school_intro/class_roster.png",
	"hallway": "res://images/middle_school_intro/hallway.png",
}
const LINES := [
	{"text": "樱花树下的石板路被春风吹得沙沙作响，几片淡粉色的花瓣打着旋儿，落在了我崭新的深色初中校服肩头上。", "background": "gate"},
	{"text": "站在私立中学气派的大门前，我下意识地扯了扯还有些僵硬的领口，深吸了一口气。"},
	{"text": "虽说已经不再是六年前那个连教室门都不敢进的一年级新生，可面对眼前陌生的校园和高耸的教学楼，心里那股久违的紧张感还是悄悄冒了出来。"},
	{"speaker": "yue", "text": "/name ——！这里这里，看这边！"},
	{"text": "一道元气满满的清亮嗓音穿过熙熙攘攘的人群，精准地钻进了我的耳朵里。"},
	{"text": "我循声望去，只见校门旁的布告栏前，月侧阳奈里正踮着脚尖朝我用力挥手。", "show_yue": true, "yue_mood": YueMood.WAVING},
	{"text": "升入初中后，她仍留着一头长发，发梢随着跳跃微微晃动，发间依旧别着那枚熟悉的星星发卡，在晨光里闪着细碎的光。"},
	{"speaker": "player", "text": "阳奈里，你怎么这么早就到了？"},
	{"text": "我快步走过去，看着她那张明媚依旧的笑脸，心里的那点局促瞬间烟消云散。"},
	{"speaker": "yue", "text": "那当然啦！今天可是初中开学第一天，我特意提前半小时出门，就是为了第一时间看分班表！"},
	{"text": "她得意地叉起腰，随即神秘兮兮地凑近了些，压低声音朝我眨了眨眼。", "yue_mood": YueMood.WINKING},
	{"speaker": "yue", "text": "你猜猜看，咱们两个有没有分到同一个班？"},
	{"speaker": "player", "text": "看你笑得这么开心，肯定是分到一年B班了吧？", "background": "roster", "show_yue": false},
	{"speaker": "yue", "text": "答对啦！不愧是 /name ，跟我心有灵犀！这样一来，初中三年我们又能一起上下学、一起去小卖部啦！"},
	{"text": "阳奈里兴奋地拉住我的袖子，眼底亮晶晶的，仿佛已经开始规划起接下来的校园生活。", "background": "gate", "show_yue": true, "yue_mood": YueMood.LAUGHING},
	{"text": "就在这时，布告栏另一侧的人群忽然安静了几分，自动让出了一条通道。"},
	{"text": "一道身姿笔挺的身影不疾不徐地走了过来。"},
	{"text": "合身的深蓝水手服穿在她身上显得格外端庄，乌黑的长发柔顺地垂在肩后，手里依旧捧着一本装帧精致的精装书。岁月似乎只拉长了她纤细的身形，却丝毫没有改变那份与生俱来的清冷与从容。", "show_fushimi": true, "fushimi_mood": FushimiMood.CALM},
	{"speaker": "fushimi", "text": "早上好，/name 同学，还有月侧同学。", "fushimi_mood": FushimiMood.GREETING},
	{"text": "伏见宫夜姬停下脚步，微微颔首，声音平静而礼貌，目光在布告栏上停留了片刻，随后转向我们。"},
	{"speaker": "player", "text": "早、早上好，伏见宫同学！你也考进这所中学了啊！"},
	{"speaker": "yue", "text": "呜哇，真是说曹操曹操到！夜姬，难道你也在一年B班吗？", "yue_mood": YueMood.SURPRISED, "fushimi_mood": FushimiMood.CURIOUS},
	{"text": "阳奈里鼓了鼓腮帮子，警惕中又带着几分熟稔地凑上前去，顺着她的视线往名单上看去。", "yue_mood": YueMood.POUTING},
	{"speaker": "fushimi", "text": "嗯，就在你们名字的下一行。"},
	{"text": "她淡淡地应了一声，合上手里的书本，视线落在我略显凌乱的衣领上，微微蹙起眉，像是条件反射般抬手帮我把歪掉的领结扶正。", "fushimi_mood": FushimiMood.STERN},
	{"speaker": "fushimi", "text": "都已经是初中生了，仪容仪表还是这么马虎。要是等会儿开学典礼上被学生会盯上，我可不会替你求情。"},
	{"speaker": "player", "text": "啊……谢、谢谢班长！不对，现在还不是班长呢……"},
	{"text": "我下意识地缩了缩脖子，耳根微微一热，熟悉的压迫感瞬间扑面而来。"},
	{"speaker": "yue", "text": "喂喂，夜姬，初中可还没开始选班干部呢，不许这么快就摆出大魔王的架子欺负 /name ！"},
	{"text": "阳奈里立刻跨前一步，顺势挽住我的另一侧手臂，理直气壮地朝伏见宫扬起下巴，可眼底却藏着几分掩不住的笑意。", "yue_mood": YueMood.WINKING},
	{"speaker": "fushimi", "text": "我只是在陈述事实。倒是月侧同学，分班表看完了就该去教学楼报到了，再磨蹭下去，靠窗的好位置可就要被别人挑走了。", "fushimi_mood": FushimiMood.AMUSED},
	{"speaker": "yue", "text": "啊！对哦，靠窗第二排！/name ，我们快走！", "yue_mood": YueMood.SURPRISED},
	{"text": "阳奈里惊呼一声，拉着我就往教学楼的方向小跑起来。", "yue_mood": YueMood.LAUGHING},
	{"text": "我被她拽得踉踉跄跄，回头望去，只见伏见宫夜姬正安静地跟在我们身后几步远的地方，晨光洒在她精致的侧脸上，嘴角似乎极其微弱地向上弯了一下。", "fushimi_mood": FushimiMood.SMILING},
	{"text": "风吹过走廊，带来新学期特有的书墨香气。左边是叽叽喳喳充满活力的阳奈里，右边是步伐沉稳、目光清澈的伏见宫，我忍不住在心里轻轻笑了一声。", "background": "hallway", "yue_mood": YueMood.SMILING},
	{"speaker": "player", "text": "看来这初中三年，也绝对不会无聊了啊。"},
]

@onready var fushimi_portrait: TextureRect = $Stage/FushimiPortrait

var yue_sheet: Texture2D
var fushimi_sheet: Texture2D


func _ready() -> void:
	yue_sheet = load(YUE_EXPRESSIONS) as Texture2D
	fushimi_sheet = load(FUSHIMI_EXPRESSIONS) as Texture2D
	super._ready()


func portrait_expression(sheet: Texture2D, expression: int) -> AtlasTexture:
	var tile_size := sheet.get_size() / Vector2(3, 2)
	var offset := Vector2(expression % 3, floorf(expression / 3.0)) * tile_size
	var portrait := AtlasTexture.new()
	portrait.atlas = sheet
	portrait.region = Rect2(offset, tile_size)
	portrait.filter_clip = true
	return portrait


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "开始初中生活  ›"


func place_portrait() -> void:
	place_portrait_at(yue_portrait, 0.27)
	place_portrait_at(fushimi_portrait, 0.73)


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	if line.has("yue_mood"):
		yue_portrait.texture = portrait_expression(yue_sheet, line["yue_mood"])
		place_portrait_at(yue_portrait, 0.27)
	if line.has("fushimi_mood"):
		fushimi_portrait.texture = portrait_expression(fushimi_sheet, line["fushimi_mood"])
		place_portrait_at(fushimi_portrait, 0.73)
	if line.has("show_yue"):
		yue_portrait.visible = line["show_yue"]
	if line.get("show_fushimi", false):
		fushimi_portrait.show()
	var speaker: String = line.get("speaker", "")
	yue_portrait.modulate = Color.WHITE if speaker == "yue" else LISTENING_TINT
	fushimi_portrait.modulate = Color.WHITE if speaker == "fushimi" else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
		"fushimi": return SocialCharacters.FUSHIMI
	return ""
