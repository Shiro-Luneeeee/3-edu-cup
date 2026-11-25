extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const ART_DIRECTORY := "res://images/fushimi_final_promise"
const LINES := [
	{"text": "初夏的晚风吹过教学楼顶层的天台，带走了白日里教室里的闷热，也吹动了栏杆旁少女乌黑的长发。", "background": "railing"},
	{"text": "距离高考只剩下最后三天。整个高三年级都被一种近乎凝固的紧张氛围笼罩着，晚自习的下课铃声刚一响起，大部分人依旧埋头在堆积如山的试卷里，只有少数几个学生悄悄溜出来透口气。"},
	{"text": "我手里攥着两罐刚从自动贩卖机买来的温热牛奶，推开天台厚重的铁门，一眼便看见了靠在栏杆边的伏见宫夜姬。", "background": "stairs"},
	{"text": "夜色下，她穿着蓝白相间的夏季校服，身姿依旧笔挺如初，只是那双总是端着精装书或学生会文件的纤细双手，此刻正安静地搭在冰凉的铁栏杆上，微仰着头，望着远处灯火通明的城市夜景。", "background": "railing"},
	{"text": "我放轻脚步走过去，将其中一罐牛奶轻轻贴在她的脸颊上。", "background": "milk"},
	{"text": "伏见宫微微一颤，侧过头看清是我后，紧绷的肩线瞬间柔和了下来，眼底漾起一抹浅浅的笑意。"},
	{"speaker": "fushimi", "text": "真幼稚啊，/name 君。要是烫到了怎么办？"},
	{"speaker": "player", "text": "我特意试过温度的，刚刚好。怎么一个人跑来吹风了？这可不像平时分秒必争的优等生作风。"},
	{"text": "我拧开另一罐牛奶喝了一口，顺势靠在她身旁的栏杆上，偏过头看着她被月光镀上一层柔光的侧脸。", "background": "talking"},
	{"text": "伏见宫接过牛奶，指尖摩挲着温热的罐身，沉默了片刻，轻声开口。"},
	{"speaker": "fushimi", "text": "大概是……书看得太多，脑子有些转不动了吧。而且，一想到过完这三天，长达十二年的学生时代就要彻底结束了，总觉得有些不真实。", "background": "worried"},
	{"text": "她的声音很轻，被晚风吹得有些散，却字字清晰地落进我心里。"},
	{"speaker": "player", "text": "紧张了吗？"},
	{"speaker": "fushimi", "text": "……一点点吧。倒不是担心考不好，只是害怕如果没能考进同一所大学，以后就不能像现在这样，每天抬头就能看见你了。"},
	{"text": "她说完，似乎觉得自己这番话有些太过直白，白皙的耳尖在夜色里悄悄染上了一抹淡淡的绯红，立刻转过头瞪了我一眼，试图找回几分往日的威严。", "background": "stern"},
	{"speaker": "fushimi", "text": "你呢？最近模拟考的成绩虽然稳住了，但数学最后那道大题还是容易粗心。要是敢在考场上犯低级错误，等成绩出来，我可不会轻饶你。"},
	{"speaker": "player", "text": "遵命，班长大人。不过你大可放心，这三年来被某位严厉的“私人家庭教师”天天盯着复习，我现在想考差都难。"},
	{"text": "我笑着举起手里的牛奶罐，轻轻碰了碰她手中的那一罐，发出一声清脆的轻响。"},
	{"speaker": "player", "text": "不管是第一志愿，还是往后更长的时间，我都会牢牢跟紧你的脚步的。毕竟，我可是从小学一年级开始，就已经习惯坐在你旁边了。"},
	{"text": "伏见宫愣了一下，随即忍不住“噗嗤”一声笑了出来。", "background": "talking"},
	{"text": "那笑容明媚而纯粹，没有了小大人般的拘谨，也没有了优等生的疏离，就像她最喜欢的童话书里，终于迎来了幸福结局的公主。"},
	{"text": "她放下牛奶罐，极其自然地伸出手，在微凉的晚风中牵住了我的手，十指相扣，掌心传来的温度坚定而踏实。", "background": "holding_hands"},
	{"speaker": "fushimi", "text": "那就说好了，/name 君。三天后的考场上，我们各自全力以赴；等铃声响起之后，就去迎接属于我们的下一个故事吧。"},
	{"speaker": "player", "text": "嗯，一言为定，夜姬。"},
	{"text": "远处的天际繁星点点，初夏的风温柔地拂过我们的肩头。从六岁那年教室里局促的初遇，到如今并肩站在十八岁的路口，所有的青涩、陪伴与心动，都在这一刻化作了最笃定的期许，静静等待着盛夏的到来。"},
]


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load("%s/%s.png" % [ART_DIRECTORY, line["background"]]) as Texture2D)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"fushimi": return SocialCharacters.FUSHIMI
	return ""
