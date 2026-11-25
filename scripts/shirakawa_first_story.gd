extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const ART_DIRECTORY := "res://images/shirakawa_first_story"
const BACKGROUNDS := {
	"classroom": "res://images/events/school.png",
	"challenge": ART_DIRECTORY + "/challenge.png",
	"pout": ART_DIRECTORY + "/pout.png",
	"thanks": ART_DIRECTORY + "/hallway_thanks.png",
	"hallway_pout": ART_DIRECTORY + "/hallway_pout.png",
	"running": ART_DIRECTORY + "/running.png",
	"hallway": ART_DIRECTORY + "/hallway.png",
}
const LINES := [
	{"text": "白川花雪的桌上堆着小山一样高的参考书，她已经低着头维持“刷题内卷模式”整整一节课了，看起来老师刚布置的作业又要被她在课间秒杀。", "background": "classroom"},
	{"speaker": "shirakawa", "text": "快快快，十分钟！来一局‘买刀买马’！", "background": "challenge"},
	{"speaker": "player", "text": "白川大学霸，下节可是数学随堂测验，你确定不临阵磨枪一下？"},
	{"speaker": "shirakawa", "text": "复习是凡人干的事，而‘买刀买马’关系到我们前后桌的尊严！来，一、二、三——我买一匹马！"},
	{"text": "这游戏规则其实幼稚得要命，无非就是猜拳攒点数、再猜对方出刀还是出马。可每次和她玩，她都能演出一种在华尔街操盘的紧张感。不知道为什么，哪怕我每次都拼尽全力去“博弈”，还是会在一连串猜拳溃败后被她拿下。我已经连败给她十几场了。"},
	{"speaker": "player", "text": "我出刀，斩马。你输了。"},
	{"speaker": "shirakawa", "text": "……不算不算！我刚才手滑了，那匹马蹄子打滑了，重来！", "background": "pout"},
	{"speaker": "player", "text": "行行行，马蹄子打滑也算正经理由。——对了，刚才老班让你抱的那摞英语卷子，走吧，我帮你分一半。"},
	{"speaker": "shirakawa", "text": "不用啦，我自己抱得动。"},
	{"speaker": "player", "text": "别逞强，楼梯口那么挤，挡着视线摔了怎么办。"},
	{"text": "她抱着剩下那半叠卷子，看着我先一步走出教室的背影，沉默了两秒，很快小跑着跟了上来。走廊的光落在她微垂的侧脸上，刚才那个在课桌前胡闹耍赖的家伙，一瞬间又安静了下来。", "background": "thanks"},
	{"speaker": "shirakawa", "text": "……谢啦。不过下次‘买刀买马’，我可不会再让着你了。"},
	{"speaker": "player", "text": "这次终于轮到我赢了，下次该轮到你连败啦。"},
	{"speaker": "shirakawa", "text": "都说了那次是马的问题啦！", "background": "hallway_pout"},
	{"text": "话音刚落，她突然把怀里剩下那半叠卷子全塞进我怀里，冲我做了个鬼脸，一溜烟顺着走廊跑没了影。", "background": "running"},
	{"speaker": "player", "text": "……可恶，原来我以前每次都会输，是因为每次都被这家伙的表情勾得走神了吗？", "background": "hallway"},
]


func lines() -> Array:
	return LINES


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"shirakawa": return SocialCharacters.SHIRAKAWA
	return ""
