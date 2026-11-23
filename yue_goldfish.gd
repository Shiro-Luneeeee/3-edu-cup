extends "res://story_dialogue.gd"

enum Mood { CHEERFUL, CURIOUS, SURPRISED, SHY, POUTING, LAUGHING }

const SocialCharacters := preload("res://social_characters.gd")
const YuePortraits := preload("res://yue_portraits.gd")
const PORTRAIT_SHEET := "res://images/yue_goldfish/expressions.png"
const PORTRAIT_REGIONS := [
	Rect2(46, 0, 452, 508), Rect2(547, 0, 452, 508), Rect2(1052, 0, 452, 508),
	Rect2(46, 512, 452, 508), Rect2(547, 512, 452, 508), Rect2(1052, 512, 452, 508),
]
const BACKGROUNDS := {
	"pond": "res://images/yue_goldfish/pond.png",
	"bag": "res://images/yue_goldfish/bag.png",
	"gift": "res://images/yue_goldfish/gift.png",
	"sunset": "res://images/yue_goldfish/sunset.png",
}
const LINES := [
	{"text": "自从那天拉过钩之后，小区公园的小池塘便成了我和阳奈里心照不宣的秘密基地。", "background": "pond"},
	{"text": "每当午后的阳光把树影拉得老长，我们总会准时出现在岸边，趴在石栏上看水里的鱼儿吐泡泡。"},
	{"text": "不过今天，我比平时还要早到了一会儿。"},
	{"text": "我小心翼翼地坐在池塘边的长椅上，双手捧着一个鼓鼓囊囊的透明水袋，连大气都不敢喘一口。"},
	{"text": "水袋里，正有一条通体赤红、尾巴像轻纱一样飘逸的小金鱼在悠闲地转着圈。", "background": "bag"},
	{"text": "这是我攒了好久的零花钱，今天一早特意去街角的花鸟店挑出来的——和池塘里那几只大红色的金鱼几乎一模一样。"},
	{"speaker": "yue", "text": "哇！ /name ，你今天怎么比我还早？", "background": "pond", "show_portrait": true, "mood": Mood.CHEERFUL},
	{"text": "清脆的脚步声伴着少女特有的雀跃从身后传来，阳奈里一路小跑着停在了长椅前。"},
	{"text": "因为我把水袋护在胸前，再加上坐得笔直，她立刻好奇地歪了歪脑袋，凑过来打量我。", "mood": Mood.CURIOUS},
	{"speaker": "yue", "text": "咦？你干嘛一动不动的，怀里藏了什么好东西呀？难道……又抓了什么奇怪的小虫子想吓唬我？"},
	{"speaker": "player", "text": "才、才不是虫子呢！"},
	{"text": "我有些紧张地咽了口唾沫，双手微微往前一递，把那个在阳光下波光粼粼的水袋举到了她面前。"},
	{"speaker": "player", "text": "给、给你的。"},
	{"text": "阳光穿透清澈的水袋，折射出一道细碎的光斑，恰好落在阳奈里微微睁大的眼眸里。", "camera_move": true, "mood": Mood.SURPRISED},
	{"text": "她先是一愣，随即像是看到了什么不可思议的宝物一样，轻轻捂住了嘴巴。"},
	{"speaker": "yue", "text": "这……这是金鱼？！真的可以送给我吗？"},
	{"speaker": "player", "text": "嗯！之前在池塘里的时候，你不是一直盯着红色的金鱼看吗？"},
	{"text": "我挠了挠有些发烫的脸颊，尽量让自己的声音听起来自然一些。"},
	{"speaker": "player", "text": "我想着，要是碰上下雨天，或者我们没办法来公园的时候，你一个人在家也能看到它……就不会觉得无聊了。"},
	{"text": "风轻轻吹过池塘的水面，带起一阵沙沙的树叶声。"},
	{"text": "向来爱捉弄我的女孩，此刻却罕见地安静了下来，长长的睫毛轻轻颤了颤，耳尖也染上了一抹淡淡的绯红。", "mood": Mood.SHY},
	{"speaker": "yue", "text": "……笨蛋 /name 。"},
	{"speaker": "player", "text": "欸？怎么突然说我笨呀，不想要的话我可拿回去了！"},
	{"speaker": "yue", "text": "才不还给你！送出去的东西就是我的了！", "mood": Mood.POUTING},
	{"text": "她像是生怕我反悔似的，赶忙伸出双手，无比珍重地接过了那个水袋，连呼吸都放轻了几分，生怕晃动太大惊扰了里面的小家伙。"},
	{"speaker": "yue", "text": "谢谢你， /name 。这是我收到的……最喜欢、最喜欢的礼物。", "mood": Mood.LAUGHING},
	{"text": "女孩抬起头，眼底映着水光与夕阳，露出一个比池塘里的涟漪还要耀眼的笑容。", "background": "gift"},
	{"text": "水袋里的小金鱼似乎也感受到了这份喜悦，欢快地摆了摆尾鳍，在水波里划出一道漂亮的弧线。"},
	{"speaker": "yue", "text": "对了，既然以后它就是我的小宝贝了，我们一起给它取个名字吧！"},
	{"speaker": "player", "text": "好啊，叫什么好呢？"},
	{"text": "夕阳将我们的影子拉得很长很长，在那个微风和煦的傍晚，池塘边的笑声仿佛比水里的鱼儿还要雀跃几分。", "background": "sunset"},
]

func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "回到公园  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("mood"):
		YuePortraits.set_portrait(yue_portrait, PORTRAIT_SHEET, PORTRAIT_REGIONS[line["mood"]])
		place_portrait()
	if line.has("background"):
		var background: String = line["background"]
		show_yue_background(load(BACKGROUNDS[background]) as Texture2D, line.get("show_portrait", false))
	if line.get("camera_move", false):
		shake_stage(0.35)
	var speaker: String = line.get("speaker", "")
	yue_portrait.modulate = Color.WHITE if speaker == "yue" else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
	return ""
