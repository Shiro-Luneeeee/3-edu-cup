extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const ART_DIRECTORY := "res://images/shirakawa_confession/"
const LINES := [
	{"text": "进入高三之后，卷子越做越厚，我们却开始格外贪恋起放学后这半个小时的安静。书包早就收拾好了，谁都没有先提离开，只是像过去无数个傍晚一样，一前一后地坐在空教室里。", "background": "window"},
	{"text": "外头操场隐约传来广播站放的轻音乐，风吹起窗帘一角。话题不知怎么从模拟考排名、小毛球最近的体重，渐渐滑到了一个更私人的角落。"},
	{"speaker": "shirakawa", "text": "……其实，我一直搞不懂一件事。"},
	{"speaker": "player", "text": "嗯？这世上还有能难倒白川大学霸的阅读理解？"},
	{"speaker": "shirakawa", "text": "我好像……一直分不清什么是友情，什么是恋情。大家总说喜欢一个人会心跳加速、会想要占有，可我觉得，两个人恋爱，不就是多了一个名分吗？我会对朋友很好、会关心他们、会试着去理解每一个人——可这些东西，对恋人来说，不也是一样的吗？"},
	{"text": "教室里突然安静下来，安静得甚至能听见走廊尽头老式挂钟“滴答、滴答”走字的声音。我的胸口像是被什么轻轻攥紧了。我太明白她在说什么了——她不是不懂，她是习惯了做那个体贴的“好人”，甚至不敢去想“唯一”这件事。"},
	{"speaker": "player", "text": "那我们……是最好的朋友，对吗？"},
	{"speaker": "shirakawa", "text": "……", "background": "hesitant"},
	{"text": "她似乎想笑一下，扯出一个平时那种“没关系啊”的表情，可对上我的视线后，那个笑容却怎么也挤不出来。"},
	{"speaker": "player", "text": "白川花雪，你总是这样。你把所有人都看得比自己更重要，对谁都温柔，对谁都认真，好像只要不越过那条线，大家就永远不会走散，永远不会像桂花那样落进雨里。"},
	{"speaker": "shirakawa", "text": "你……"},
	{"speaker": "player", "text": "可是，爱不是一碗水端平的。爱是要学会偏心，是要允许自己在喜欢的人面前自私一点的。"},
	{"speaker": "shirakawa", "text": "……那按你说的，应该是什么样的呢？我不太能理解……也好像，从来没学过怎么做到这种偏心。"},
	{"text": "那一刻，我突然看清了她所有“姐姐感”与“妹妹感”之下的真实模样——她表面上是无所不能的资优生，其实只是个害怕失去、小心翼翼把自己包裹起来的小女孩。所有的线索都在这一瞬间串联了起来：初见时的冷笑话、课间胡闹的午后、巷口共同收养的小毛球、桂花树下那句“一直做朋友”……原来只差一个人，亲手把她拉出那道安全线。"},
	{"speaker": "player", "text": "在我看来，友情和恋情根本不一样。", "background": "moved"},
	{"speaker": "player", "text": "朋友会一起走过一段路，但如果是喜欢的人——"},
	{"speaker": "player", "text": "你会记得她第一天入学时别着的小狗胸针，和耳边那只圆滚滚的兔绒发卡；会在‘买刀买马’的时候因为她一个鬼脸就走神连败十几场；会在她盯着桂花发呆的时候，只想把所有的晴天都攒起来送给她。"},
	{"speaker": "shirakawa", "text": "……"},
	{"text": "夕阳的最后一道橘红色余晖斜斜切过她的脸颊，照亮了她发间那只毛茸茸的兔子发卡，也照亮了她眼底剧烈摇晃的光。"},
	{"speaker": "player", "text": "光用嘴讲道理，你大概还是会觉得像在做阅读理解吧。"},
	{"speaker": "player", "text": "——白川花雪，让我印证给你看。我可是一个自私又偏心的人哦。"},
	{"text": "空气凝固了短短两秒。教室外操场的晚风恰在此时穿堂而过，吹动了桌上摊开的草稿纸。她没有躲开，也没有像往常一样用冷笑话逃跑，只是在逐渐沉下来的暮色里，轻轻地、几乎不可察地“嗯”了一声。", "background": "smile"},
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
