extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const ART_DIRECTORY := "res://images/shirakawa_osmanthus/"
const LINES := [
	{"text": "别人的秋游书包里装的是薯片和相机，白川花雪的背包侧面却插着一把环卫工同款的长柄垃圾夹，左手还拎着一只鼓鼓囊囊的黑色塑料袋。", "background": "trail"},
	{"speaker": "player", "text": "说真的，别人来秋游是看风景，咱们俩像是来做社会实践的。"},
	{"speaker": "shirakawa", "text": "风景也要有人保护才好看嘛。而且你明明没有工具，还不是乖乖跟着我捡了一路。", "background": "tree"},
	{"text": "不知不觉间，我们和大部队拉开了好长一段距离。远处同学们的嬉笑声渐渐被风吹散，山道上只剩下踩碎枯叶的沙沙声，和空气里浓得化不开的桂花香。", "background": "trail"},
	{"speaker": "shirakawa", "text": "桂花……是秋天最后的颜色。", "background": "tree"},
	{"speaker": "player", "text": "你怎么突然变得这么深沉文艺了？"},
	{"speaker": "shirakawa", "text": "没什么。……其实，我以前很讨厌桂花开的时候。"},
	{"speaker": "player", "text": "为什么？桂花这么香，这么好看。"},
	{"speaker": "shirakawa", "text": "因为桂花总是不知不觉间，就浮出腐烂的气味了。"},
	{"text": "我不解地看着她，却在那一瞬间撞进了她眼底掩藏得很深的悲伤。"},
	{"speaker": "shirakawa", "text": "外婆还在的时候，院子里就种着一棵老桂花树。每年十月花落了一地，我总吵着要她帮我收起来做桂花糕。"},
	{"speaker": "shirakawa", "text": "后来有一年秋天，桂花开得特别好，却突然下了一场大雨。我还在担心外婆的桂花没来得及收就要被雨水打落了，可等我放学回家，却发现树还在，人已经不在了。", "background": "rain"},
	{"text": "山风吹过，几片金黄的花瓣擦过她的肩膀。", "background": "tree"},
	{"speaker": "shirakawa", "text": "那天雨水一直淅淅沥沥地下，浓烈的秋意裹着金灿灿的桂花砸在泥水里。我蹲在树下，摸了摸那些潮湿又浓烈的花香——像眼泪，又像没来得及说完的话。从那以后我就总觉得，桂花大概是一年里美好凋落的最后时刻吧；再往后，就只能在腐烂里回忆过去了。", "background": "rain"},
	{"text": "那一刻我突然意识到，平时那个整天乐呵呵、说着傻话的白川花雪，心里其实一直留着一块安静又脆弱的角落。她不是不懂难过，只是太害怕“告别”，所以习惯把沉重的东西折起来，藏在玩笑背后。", "background": "tree"},
	{"speaker": "player", "text": "那今年这棵树开得这么好，外婆应该也会喜欢。你没忘记花，花就不会真正枯萎；你没忘记她，她就一直都在。", "background": "petal"},
	{"speaker": "shirakawa", "text": "……嗯。其实也没那么讨厌了。至少现在，还有人愿意陪我一起走这段路。"},
	{"text": "她吸了吸鼻子，像是要把那点罕见的脆弱重新收好。下一秒，她松开手里的塑料袋，迎着风轻轻张开双臂，笑容认真得近乎虔诚，像是在立下一个郑重的誓言。", "background": "promise"},
	{"speaker": "shirakawa", "text": "这个世界上有那么多让人难过的事，但我还是想记住并珍惜所有美好的、开心的瞬间。——所以，请和我一直做朋友吧。"},
	{"speaker": "player", "text": "好。"},
	{"text": "那时的我还不知道，她口中那句“一直做朋友吧”，既是她给我们的承诺，也是她为了不失去我，亲手画下的一道安全线。"},
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
