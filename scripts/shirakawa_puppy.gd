extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const ART_DIRECTORY := "res://images/shirakawa_puppy/"
const LINES := [
	{"speaker": "shirakawa", "text": "嘘——你听见了吗？", "background": "alley"},
	{"text": "顺着她指的方向看去，巷尾电线杆旁的纸箱里，正缩着一只浑身脏兮兮的小奶狗，湿漉漉的眼睛怯生生地望着我们。", "background": "puppy"},
	{"speaker": "shirakawa", "text": "被人丢掉的吗……周围没有母狗，也没有项圈。", "background": "gentle"},
	{"speaker": "player", "text": "看着也就一两个月大，天快黑了，留在这里肯定撑不过今晚。"},
	{"text": "平时总爱闹腾的她，此刻却安静得像变了个人。她脱下自己的校服外套轻轻垫在纸箱边，仔细检查了小狗的状态，抬头看我时，眼神格外冷静且有条理。"},
	{"speaker": "shirakawa", "text": "我家我妈白天上班，能照顾一半时间，但周末有时候没人。你呢？"},
	{"speaker": "player", "text": "我倒是随时可以，不过我爸妈不一定同意我一个人长期养。"},
	{"speaker": "shirakawa", "text": "那我们共同收养吧。小狗一周住我那儿，一周住你那儿。", "background": "promise"},
	{"speaker": "player", "text": "这算什么，联合监护权？"},
	{"speaker": "shirakawa", "text": "对啊。那从今天起，你就是小狗的爸爸，我是妈妈。不许反悔，爸爸。"},
	{"text": "说完，她立刻低下头，用一种哄小孩般的语气跟纸箱里的小家伙嘀咕起来。", "background": "gentle"},
	{"speaker": "shirakawa", "text": "小毛球，我以后就是你美丽大方的妈妈了。至于旁边那个呢，是你的爸爸——虽然人傻傻的，长得也没有你妈妈好看，但他是个靠谱的小傻瓜。"},
	{"speaker": "player", "text": "喂，你是不是当着我的面说我坏话了？"},
	{"speaker": "shirakawa", "text": "没有呀！不信你问小毛球。小毛球你说对吧，你爸爸在欺负你妈妈呢。", "background": "hug"},
	{"text": "她一边说，一边装出委屈巴巴的样子，两只小手在眼睛前面握成拳头左右摇晃，比了个夸张的“抹眼泪”手势。"},
	{"speaker": "player", "text": "好好好，我错了……不过，我还没同意它叫‘小毛球’呢。"},
	{"text": "夕阳落在她别着小狗胸针的衣领上，也落在纸箱里小狗蹭着她指尖的小脑袋上。那天之后，我们的聊天记录里不再只有作业和考卷，多了数不清的狗粮链接、交接时间表，和一只叫“小毛球”的小狗每天的睡颜照片。", "background": "gentle"},
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
