extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const ART_DIRECTORY := "res://images/shirakawa_snow/"
const LINES := [
	{"text": "距离高考只剩一百天出头，冬天的教室里门窗紧闭，连呼吸都带着试卷油墨和暖气混杂的沉闷味道。我正盯着密密麻麻的阅读理解发呆，余光里，灰蒙蒙的窗外忽然飘进了一点极淡的白。", "background": "classroom"},
	{"text": "下雪了。南方的雪总是下得很吃力，一小片、一小片，像在半空中犹豫着要不要落下来；可只要一沾到地面，又会瞬间化成一滩冰冷的水渍，连一点留存过的痕迹都抓不住。"},
	{"text": "前桌的她不知什么时候停下了笔，微微侧过头望向窗外。她背对着我，我看不见她的表情，只能看见她被冷风吹得有些微红的耳尖，和发间别着的那个白色兔绒发卡——毛茸茸的一小团，在阴沉压抑的高三考场里，成了我眼里唯一鲜活的颜色。"},
	{"text": "那一瞬间，卷面上那些密密麻麻的英文单词突然失去了全部意义。我鬼使神差地希望，这场考试永远不要结束，或者外面的雪，能下得再久一点。"},
	{"text": "走廊上冷风呼啸，大多数同学交完卷就缩回教室搓手了，只有白川花雪裹着那条厚实的浅米色围巾，一溜烟跑到栏杆边，仰起头朝着灰白的天空张开了小嘴巴。", "background": "snowflakes"},
	{"speaker": "player", "text": "喂，你干嘛呢，风这么大，刚考完试也不怕冻感冒。"},
	{"speaker": "shirakawa", "text": "我们来比谁吃到的雪花多吧！输的人请喝热奶茶！"},
	{"text": "可话刚说完，她看着我只拉了一半拉链的校服领口，眉头轻轻蹙了一下——那是她“姐姐感”冒出来时的习惯性动作。她二话不说，抬手把脖子上长长的浅米色围巾解下一半，踮起脚尖，自然地绕到了我的颈边。", "background": "scarf"},
	{"text": "带着她体温、混着淡淡洗衣液清香的柔软针织贴上我脖颈的那一刻，周围呼啸的冷风仿佛一下子被隔绝在了外面。我们的距离一下子拉近到连彼此呼出的白气都交融在一起，我甚至能数清她眼睫毛上沾着的一丁点水汽。我的心跳重重地漏了一拍。"},
	{"speaker": "player", "text": "……好，比就比。"},
	{"text": "过了几分钟，雪势渐渐小了，细碎的雪粒落在走廊栏杆上，几乎瞬间就化成了水珠。白川花雪盯着栏杆上迅速消失的水痕，刚才还雀跃的眼神微微暗了一点，嘴角轻抿着，露出一点不易察觉的落寞。"},
	{"speaker": "shirakawa", "text": "南方的雪总是这样……还没来得及堆雪人，就先化掉了。你说，雪到底是甜的，还是冰的呢？"},
	{"text": "我听出了她话里没说出口的那半句——像桂花，像高三，像所有还没来得及握紧就要流走的时间。她看着我，眼睛亮晶晶的，却藏着一丝连她自己都没察觉的期待，像是在等那个在夕阳教室里许下的“印证”。"},
	{"speaker": "player", "text": "像迷人的巧克力一样——温暖的甜。"},
	{"speaker": "shirakawa", "text": "……笨蛋，雪怎么可能是温暖的。"},
	{"speaker": "player", "text": "雪是冰的，但和你一起淋雪、还分了我一半围巾的现在，是暖的啊。"},
	{"text": "风还在轻轻地吹，她发间的白色兔绒发卡在灰白的天色里微微晃动。她没有再反驳，只是把半张脸更深地埋进了浅米色围巾里，耳根悄悄红透了，只露出一双微微弯起的眼睛，安静地望向我。", "background": "smile"},
]


func lines() -> Array:
	return LINES


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(ART_DIRECTORY + line["background"] + ".png") as Texture2D)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"shirakawa": return SocialCharacters.SHIRAKAWA
	return ""
