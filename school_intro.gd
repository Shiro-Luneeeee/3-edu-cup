extends "res://story_dialogue.gd"

enum FushimiMood { CALM, ASKING, EXPLAINING, STARTLED, SMILING, FOCUSED }

const RoundCalendar := preload("res://round_calendar.gd")
const SocialCharacters := preload("res://social_characters.gd")
const YuePortraits := preload("res://yue_portraits.gd")
const CLASSROOM_ART := preload("res://images/classroom.png")
const FUSHIMI_SHEET := "res://images/character/fushimi_school_expressions.png"
const FUSHIMI_REGIONS := {
	FushimiMood.CALM: Rect2(66, 0, 416, 500),
	FushimiMood.ASKING: Rect2(560, 0, 416, 500),
	FushimiMood.EXPLAINING: Rect2(1074, 0, 416, 500),
	FushimiMood.STARTLED: Rect2(66, 512, 416, 500),
	FushimiMood.SMILING: Rect2(560, 512, 416, 500),
	FushimiMood.FOCUSED: Rect2(1074, 512, 416, 500),
}
const LINES := [
	{"text": "崭新的书包带子勒在肩膀上，有些微沉，但更多的是说不出的新鲜感。"},
	{"text": "我站在一年级A班的教室门口，望着里面攒动的人头，心里多少有些打鼓。"},
	{"text": "虽说早就到了上学的年纪，可要从熟悉的小区公园走进这方陌生的天地，还是让人难免紧张。"},
	{"speaker": "yue", "text": "/name ，这边这边！"},
	{"text": "熟悉的清亮嗓音穿透了教室里的嘈杂，我循声望去，只见月侧阳奈里正站在靠窗的第二排，朝我用力地挥着手"},
	{"speaker": "player", "text": "阳奈里，你来得好早啊"},
	{"text": "我小跑着过去，顺势在她旁边的空位坐下，心里的那点不安瞬间消散了大半"},
	{"speaker": "yue", "text": "那是当然，今天可是我们成为小学生的第一天呢！我特意把新发卡都戴上了，好看吗？", "mood": YuePortraits.Mood.PROUD},
	{"text": "女孩凑近了些，得意地偏过头，发梢上的星星发卡在晨光里晃了晃"},
	{"speaker": "player", "text": "嗯，很好看"},
	{"speaker": "yue", "text": "嘻嘻，我就知道你会这么说", "mood": YuePortraits.Mood.LAUGHING},
	{"text": "正当我俩凑在一起小声嘀咕时，旁边走道突然传来一阵轻微的脚步声"},
	{"text": "一个背着深蓝色书包、身姿笔挺的女生停在了我们的课桌旁", "fushimi_mood": FushimiMood.CALM},
	{"text": "她的校服穿得一丝不苟，连衣领都叠得整整齐齐，手里还捧着一本厚厚的图画百科"},
	{"speaker": "优等生", "text": "打扰一下，请问这里是靠窗第二排吗？", "fushimi_mood": FushimiMood.ASKING},
	{"text": "女孩的声音不高，却透着一股同龄人少有的冷静与礼貌"},
	{"speaker": "yue", "text": "咦？对呀，怎么啦？", "mood": YuePortraits.Mood.PUZZLED},
	{"speaker": "优等生", "text": "这是老师提前排好的座位表，我的名字在这个位置。", "fushimi_mood": FushimiMood.EXPLAINING},
	{"text": "她伸出白皙的手指，指向贴在桌角的一张小小姓名贴，上面工工整整地印着“伏见宫夜姬”五个字"},
	{"speaker": "player", "text": "啊……原、原来这里有名字啊！对不起，我刚才没注意看！", "fushimi_mood": FushimiMood.STARTLED},
	{"text": "我慌忙站起身，脸颊有些发烫，手忙脚乱地把刚放下的书包拎起来"},
	{"speaker": "yue", "text": "呜……还以为能和 /name 坐同桌呢", "mood": YuePortraits.Mood.POUTING},
	{"text": "阳奈里鼓起腮帮子，有些不情愿地嘟囔了一句，但还是乖乖挪到了旁边的位置"},
	{"speaker": "伏见宫夜姬", "text": "没关系，第一天难免会看漏。我叫伏见宫夜姬，请多指教。", "fushimi_mood": FushimiMood.SMILING},
	{"text": "她微微颔首，动作标准得像是电视里的小大人，随后便安静地坐下，把书包规规矩矩地挂在了桌侧的挂钩上"},
	{"speaker": "player", "text": "我叫 /name ，她叫月侧阳奈里，请、请多指教"},
	{"text": "我有些局促地学着她的样子点了点头，心里暗自感叹，原来同龄人里也有这么厉害、这么像大人的存在"},
	{"text": "就在这时，教室前门被轻轻推开，一阵清脆的高跟鞋声由远及近"},
	{"text": "一位戴着无框眼镜、笑容温婉的年轻女老师走上了讲台，手里抱着一叠崭新的课本", "camera_move": true},
	{"speaker": "老师", "text": "同学们早上好呀，大家请先回到自己的座位上坐好哦", "mood": YuePortraits.Mood.CHEERFUL},
	{"text": "温柔的声音瞬间让喧闹的教室安静了下来，所有人的目光齐刷刷地投向讲台"},
	{"speaker": "林老师", "text": "欢迎大家来到一年级A班，我是你们的班主任，大家可以叫我林老师。"},
	{"text": "林老师在黑板上工整地写下自己的名字，转过身时，目光刚好扫过我们这一排"},
	{"speaker": "林老师", "text": "接下来的日子里，大家要在这里一起学习、一起长大，希望每位同学都能交到好朋友。"},
	{"text": "我偷偷瞄了一眼左边正朝我挤眉弄眼的阳奈里，又看了一眼右边已经端正坐好、拿出铅笔盒的伏见宫夜姬", "mood": YuePortraits.Mood.WINKING, "fushimi_mood": FushimiMood.FOCUSED},
	{"speaker": "player", "text": "嗯，一定会很有趣的吧"},
	{"text": "我在心里默默想着，迎着窗外洒进来的阳光，握紧了手中的铅笔。"},
]

@onready var fushimi_portrait: TextureRect = $Stage/FushimiPortrait


func _ready() -> void:
	art.texture = CLASSROOM_ART
	YuePortraits.show_on(yue_portrait, RoundCalendar.SCHOOL_AGE)
	place_portrait()
	super._ready()


func lines() -> Array:
	return LINES


func place_portrait() -> void:
	place_portrait_at(yue_portrait, 0.27)
	place_portrait_at(fushimi_portrait, 0.73)


func stage_line(line: Dictionary) -> String:
	if line.get("camera_move", false):
		shake_stage(0.35)
	if line.has("mood"):
		YuePortraits.show_on(yue_portrait, RoundCalendar.SCHOOL_AGE, line["mood"])
	if line.has("fushimi_mood"):
		var portrait := AtlasTexture.new()
		portrait.atlas = load(FUSHIMI_SHEET) as Texture2D
		portrait.region = FUSHIMI_REGIONS[line["fushimi_mood"]]
		portrait.filter_clip = true
		fushimi_portrait.texture = portrait
		fushimi_portrait.show()
		place_portrait()
	var speaker: String = line.get("speaker", "")
	if speaker == "yue":
		yue_portrait.show()
	yue_portrait.modulate = Color.WHITE if speaker == "yue" else LISTENING_TINT
	var fushimi_speaking := speaker == "优等生" or speaker == "伏见宫夜姬"
	fushimi_portrait.modulate = Color.WHITE if fushimi_speaking else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
	return speaker
