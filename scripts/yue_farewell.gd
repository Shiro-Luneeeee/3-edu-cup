extends "res://scripts/story_dialogue.gd"

const SocialCharacters := preload("res://scripts/social_characters.gd")
const BACKGROUNDS := {
	"park": "res://images/yue_goldfish/sunset.png",
	"bedroom": "res://images/bedroom.png",
	"yue_room": "res://images/yue_farewell/room.png",
	"fishbowl": "res://images/yue_farewell/fishbowl.png",
	"yue_closeup": "res://images/yue_farewell/closeup.png",
}
const LINES := [
	{"text": "时光像池塘边疯长的水草一样，悄无声息地跨过了好几个春夏秋冬。", "background": "park"},
	{"text": "转眼间，我们已经从刚背起书包的小豆丁，长成了五六年级的半大小子。"},
	{"text": "小区公园的小池塘依然在那里，只是午后的阳光洒下来时，池边长椅上的两个人不再像小时候那样一坐就是一下午，各自都有了各自的功课与心事。"},
	{"text": "不过，阳奈里书桌旁那个小小的玻璃鱼缸，却始终占据着最显眼的位置。"},
	{"text": "那条当年我用攒了好久的零花钱买来的红金鱼，陪着她度过了整整好几个年头，尾巴早就长成了华丽又修长的模样。"},
	{"text": "直到一个闷热的傍晚，我刚做完作业，就接到了阳奈里打来的电话。", "background": "bedroom"},
	{"text": "电话那头没有往日那种清脆得像风铃一样的笑声，只有一阵极轻、极克制的抽泣声，断断续续地传过来。"},
	{"speaker": "player", "text": "阳奈里？怎么了，声音听起来怪怪的？"},
	{"text": "我心里咯噔一下，抓起外套就往她家跑去。"},
	{"text": "推开她家房门的时候，屋里没有开大灯，只有鱼缸旁边一盏小小的台灯亮着，昏黄的光线落在阳奈里垂着的发顶上。", "background": "yue_room"},
	{"text": "她坐在书桌前，双手轻轻捧着那个透明的玻璃鱼缸，一动不动，连我走近都没有察觉。"},
	{"text": "缸底的水面安静得没有一丝波澜，那抹熟悉的赤红色侧躺在水草边，再也没有摆动过一下尾鳍。", "background": "fishbowl"},
	{"speaker": "player", "text": "……它……"},
	{"text": "到了嘴边的话突然变得干涩无比，我看着那条陪了我们这么多年的小生命，胸口像是被什么东西轻轻压住，一时竟说不出完整的句子。"},
	{"speaker": "yue", "text": " /name ……它走了。", "background": "yue_room"},
	{"text": "阳奈里抬起头，眼眶红红的，鼻尖也泛着微红，显然已经哭过一阵子了，却还在强忍着不让眼泪掉下来。"},
	{"speaker": "yue", "text": "明明昨天还好好的，还会游过来找我要吃的……怎么今天突然就……"},
	{"text": "女孩的声音微微发颤，指尖隔着冰凉的玻璃轻轻碰了碰鱼缸壁，像是怕惊扰了它，又像是在做最后的道别。"},
	{"speaker": "player", "text": "金鱼的寿命本来就不算特别长，它陪了你这么多年，已经很努力、很开心了吧。"},
	{"text": "我走上前，挨着她在书桌旁坐下，一时之间也不知道该怎么安慰向来元气满满的她，只能笨拙地顺着她的话往下说。"},
	{"speaker": "player", "text": "毕竟是当年我挑出来的嘛，说不定它心里一直记着，这是阳奈里最喜欢的礼物，所以才撑了这么久。"},
	{"speaker": "yue", "text": "……你就会说这种让人更想哭的话。"},
	{"text": "阳奈里终于没忍住，一滴眼泪砸在桌面上，晕开一小块深色的印记。她抬手胡乱擦了擦脸，却怎么也擦不干净。"},
	{"speaker": "yue", "text": "不过……你说得对。它陪了我好久好久，下雨天的时候，看不见你的日子里，都是它陪着我的。"},
	{"text": "她轻轻把鱼缸放在桌角，转过头看向我，眼神里虽然还带着失去伙伴的难过，却多了一份五六年级少年少女才有的沉静与释然。", "background": "yue_closeup", "camera_move": true},
	{"speaker": "yue", "text": " /name ，明天我们去公园里找个树荫下的地方，把它埋了吧。就埋在以前我们经常一起看鱼的那个小池塘旁边。"},
	{"speaker": "player", "text": "好，我陪你一起去。"},
	{"text": "我点了点头，伸出手轻轻拍了拍她的肩膀。"},
	{"text": "窗外的晚风吹过树梢，带走了白日的暑气，也仿佛把一段纯真又漫长的童年时光，悄悄画上了一个温柔的句号。"},
]


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "回到公园  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	if line.get("camera_move", false):
		shake_stage(0.35)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
	return ""
