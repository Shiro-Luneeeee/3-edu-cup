extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const FushimiPortraits := preload("res://fushimi_portraits.gd")
const BACKGROUNDS := {
	"quiz": "res://images/fushimi_tutoring/quiz.png",
	"classroom": "res://images/classroom.png",
	"tutoring": "res://images/fushimi_tutoring/tutoring.png",
	"farewell": "res://images/fushimi_tutoring/farewell.png",
}
const LINES := [
	{"text": "最近一次小测验的成绩单发下来时，我盯着卷面上那几个刺眼的红叉，感觉整个人都要石化了。", "background": "quiz"},
	{"text": "眼下的尴尬和窘迫，让我想起这些年来和她做同桌的日常——平时她总是端端正正地坐着，对待纪律扣分和作业抄袭毫不留情，是班上令众人敬畏的“魔头”班长；可偏偏在学习上，我却总是像这样一不小心就栽跟头。"},
	{"text": "班主任林老师在讲台上轻描淡写地提了一句：“这次测验低于及格线的同学，下周要留在教室补习哦，尤其是某些最近心思不在学习上的同学。”", "background": "classroom"},
	{"text": "我的视线不受控制地飘向身旁。"},
	{"text": "伏见宫夜姬正端端正正地坐着，手里拿着红笔，安静地核对自己的错题。她的卷面上几乎是一片干净的满分，只有一道附加题因为书写不够工整被扣了半个符号似的微瑕，可即便如此，她眉头也微微蹙着，仿佛犯了什么大错。", "mood": FushimiPortraits.Mood.FOCUSED},
	{"speaker": "player", "text": "……呜，完了，这下彻底没脸见人了。"},
	{"text": "我把成绩单往抽屉最深处塞了塞，恨不得立刻钻进地缝里。"},
	{"text": "下课铃一响，教室里的人几乎跑光了，唯有我还磨磨蹭蹭地收拾着书包，准备独自承受这沉重的打击。"},
	{"text": "就在我背起书包准备起身时，一只白皙的手突然按在了我的练习册上。"},
	{"text": "我愣了一下，抬起头，撞进伏见宫那双清冷却又带着几分认真审视的眼眸里。", "mood": FushimiPortraits.Mood.CALM},
	{"speaker": "fushimi", "text": "/name 同学，你的错题，我刚才看了一眼。"},
	{"speaker": "player", "text": "啊……那个，班长，我知道我考得很烂，你不用特意提醒我的，我这就回去反省……"},
	{"speaker": "fushimi", "text": "谁要提醒你了。", "mood": FushimiPortraits.Mood.FOCUSED},
	{"text": "她微微皱起眉，从自己的书包里抽出一本厚厚的笔记本和一支铅笔，动作利落地摆在了我的桌面上。"},
	{"speaker": "fushimi", "text": "做了这么多年同桌，放任你在测验里栽跟头，作为班长也有失职的地方。今天先留下来一小时吧。我把基础题型给你理一遍，你要是敢走神，我就把你今天错的题抄十遍。", "mood": FushimiPortraits.Mood.EXPLAINING},
	{"speaker": "player", "text": "……是、是！长官！"},
	{"text": "我条件反射地挺直了腰板，等反应过来自己说了什么时，耳根又是一热。"},
	{"text": "伏见宫轻轻哼了一声，没有拆穿我的失态，而是拉过旁边的椅子坐下，把笔记本推到我们中间。"},
	{"speaker": "fushimi", "text": "先看第一题。加减法进位的时候，你总是漏掉进上来的那个“1”，对吧？", "background": "tutoring"},
	{"speaker": "player", "text": "唔……好像确实是这样，一算快就忘了。"},
	{"speaker": "fushimi", "text": "那就把速度降下来。写每一步的时候，在心里默念一遍。来，试着做做看。"},
	{"text": "她拿起铅笔，在草稿纸上写下一道简单的题目，随后安静地坐在一旁看着我。"},
	{"text": "阳光斜斜地照进空荡荡的教室，空气里只有铅笔摩擦纸面的沙沙声。"},
	{"text": "起初我还因为紧张而手忙脚乱，连简单的算式都算得磕磕绊绊，可伏见宫并没有像平时那样冷冰冰地训斥我，也没有露出不耐烦的神色。每当我卡壳时，她总会用笔尖轻点一下关键的地方，用平缓而清晰的语调引导我一步步想下去。"},
	{"speaker": "fushimi", "text": "这里错了。不是让你直接猜答案，你看清楚数字的位数。"},
	{"speaker": "player", "text": "啊……对哦，我又跳步了。"},
	{"speaker": "fushimi", "text": "嗯，这次算对了。保持这个节奏。"},
	{"text": "不知过了多久，窗外的天色渐渐染上了一层柔和的橘红。"},
	{"text": "当我终于把那张让人头疼的练习纸完整地做完一遍，并且准确率出奇地高时，一种久违的轻松感忽然涌上了心头。"},
	{"speaker": "player", "text": "呼……竟然真的做出来了！班长，你教得也太清楚了吧！"},
	{"text": "伏见宫合上笔记本，微微仰起头看了看窗外的晚霞，随后转过头看向我，眼神里少了几分往日的威严，多了一丝不易察觉的温和。"},
	{"speaker": "fushimi", "text": "只是你以前没有静下心来而已。其实只要肯认真看题，你的反应并不算慢。"},
	{"text": "她把笔记本和铅笔收好，站起身拍了拍校服裙摆，居高临下地看着我。"},
	{"speaker": "fushimi", "text": "今天到这里就够了。明天同一时间，继续。别迟到，/name 同学。"},
	{"speaker": "player", "text": "好！明天绝对准时！"},
	{"text": "我看着她拎着书包走向门口的背影，心里那份原本沉甸甸的失落感早已一扫而空。", "background": "farewell"},
	{"speaker": "fushimi", "text": "对了——"},
	{"text": "她在门边停下脚步，回头瞥了我一眼，嘴角轻轻弯了一下。"},
	{"speaker": "fushimi", "text": "下次测验要是再考这么差，可就不只是补习这么简单了。加油吧，我的“同桌”。"},
	{"text": "门轻轻合上，脚步声渐渐远去。我坐在夕阳的余晖里，看着桌上整整齐齐的笔记，第一次觉得学习好像也没有那么可怕了。", "background": "classroom"},
]

@onready var fushimi_portrait: TextureRect = $Stage/FushimiPortrait


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func place_portrait() -> void:
	place_portrait_at(fushimi_portrait, 0.73)


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
		fushimi_portrait.hide()
	if line.has("mood"):
		FushimiPortraits.show_school(fushimi_portrait, line["mood"])
		place_portrait()
		fushimi_portrait.show()
	var speaker: String = line.get("speaker", "")
	fushimi_portrait.modulate = Color.WHITE if speaker == "fushimi" else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"fushimi": return SocialCharacters.FUSHIMI
	return ""
