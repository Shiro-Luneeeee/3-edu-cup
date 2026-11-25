extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const BACKGROUNDS := {
	"classroom": "res://images/classroom.png",
	"worried": "res://images/yue_final_promise/worried.jpg",
	"protest": "res://images/yue_final_promise/protest.jpg",
	"relieved": "res://images/yue_final_promise/relieved.jpg",
	"teasing": "res://images/yue_final_promise/teasing.jpg",
}
const LINES := [
	{"text": "5月的某天，距离高考还有大约两周时间。", "background": "classroom"},
	{"text": "不像文学作品中常有的“紧张到连头太当胃穿孔的高中生”那样，包括我在内的高三生们"},
	{"text": "在这最后的时光里，反而只剩下了平淡与些许的麻木感。"},
	{"text": "到了这种关头，自己大概是什么水平，大家早已心知肚明"},
	{"text": "名列前茅的资优生，亦或是排名垫底的吊车尾"},
	{"text": "无论对自己的成绩有什么看法，现在也早已接受了"},
	{"text": "不能改变什么，也只能听天由命地一遍遍重复着"},
	{"text": "做题、对答案、订正错题……如此循环往复的日常。"},
	{"speaker": "yue", "text": "/name ，你说，我们真的能考到同一所大学吗", "background": "worried"},
	{"text": "中午，我和阳奈里一起吃便当时，她突然停下筷子问我"},
	{"text": "她的担忧不无道理，毕竟她的成绩确实和我有着一定差距。"},
	{"speaker": "player", "text": "如果是同一座城市的话……"},
	{"speaker": "yue", "text": "不行！", "background": "protest", "shake": 1.0},
	{"text": "我的话还没说完，阳奈里就有些小孩子气地提高了音量"},
	{"speaker": "yue", "text": "只是同一座城市，不行！"},
	{"speaker": "yue", "text": "如果不能天天见面的话，我会很寂寞的！"},
	{"speaker": "yue", "text": "只是擦肩而过，以“同城校友”的身份互相安慰，我才不要那样！"},
	{"speaker": "yue", "text": "说不定就会被哪个家伙趁虚而入，把你给抢走了！"},
	{"speaker": "yue", "text": "所以，我绝对、绝对要和 /name 考进同一所大学！"},
	{"text": "说着，阳奈里握紧了手中的筷子，鼓起脸颊一脸认真地宣誓道。"},
	{"text": "说完那句带着几分孩子气却又无比认真的宣言，阳奈里像是耗尽了全部的底气，耳根悄无声息地红透了一片。", "background": "worried"},
	{"text": "她飞快地夹起一块炸猪排塞进嘴里，试图用咀嚼来掩饰自己此刻有些慌乱的心跳，目光却又忍不住偷偷往我这边瞟。"},
	{"speaker": "player", "text": "……你这算盘打得也太响了吧。"},
	{"text": "我看着她这副明明嘴硬得像只小刺猬、眼神却亮晶晶的模样，原本还觉得有点沉重的午后，忽然变得轻松又鲜活起来。"},
	{"speaker": "player", "text": "不过，听起来倒也不是完全没有道理。"},
	{"speaker": "yue", "text": "欸？真的吗？"},
	{"text": "阳奈里差点被嘴里的食物噎住，赶忙端起旁边的麦茶喝了一大口，眼睛瞪得圆圆地看着我。"},
	{"speaker": "yue", "text": "那、那你的意思是……你也想和我考同一所大学？"},
	{"speaker": "player", "text": "嗯，毕竟要是分开太远，以后想一起去小区公园散步、或者顺路买点什么吃的，可就麻烦多了。", "background": "relieved"},
	{"text": "我说得很平淡，语气里却藏着连我自己都未曾察觉的认真。"},
	{"text": "从小到大，好像很多事情的轨迹都是这样——原本只是随口一提的约定，或是某个午后突如其来的念头，走着走着，就变成了理所当然的方向。"},
	{"text": "午休的铃声隐隐约约从走廊尽头传来，窗外的风吹过树梢，带起一片细碎的绿影。", "shake": 0.35},
	{"text": "阳奈里看着我，脸颊上的红晕渐渐褪去了一些，取而代之的是一种带着几分狡黠与笃定的笑意。", "background": "teasing"},
	{"speaker": "yue", "text": "哼哼，这可是你亲口说的哦。"},
	{"text": "她把吃得干干净净的便当盒盖上，双手撑在课桌上，微微探过身子凑近我。"},
	{"speaker": "yue", "text": "既然这样，从今天开始，我每天都要监督你复习！要是最后没能考进同一所学校，我可不会轻易放过你的。"},
	{"speaker": "player", "text": "好啊，那我也得好好看着你，别刷题刷到一半又偷偷走神画画了。"},
	{"speaker": "yue", "text": "才、才没有经常走神呢！"},
	{"text": "我们相视一笑，那些积攒在心底、关于未来的不安与模糊的担忧，仿佛都在这一刻被午后的阳光晒得暖洋洋的。"},
	{"text": "高考的倒计时还在一天天逼近，试卷与错题依然堆得像小山一样高，可至少在这一刻，我知道自己并不是孤身一人在往前走。"},
]


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	if line.has("shake"):
		shake_stage(line["shake"])
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
	return ""
