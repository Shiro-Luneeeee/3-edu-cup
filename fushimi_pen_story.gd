extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const FushimiPortraits := preload("res://fushimi_portraits.gd")
const YuePortraits := preload("res://yue_portraits.gd")
const RoundCalendar := preload("res://round_calendar.gd")
const BACKGROUNDS := {
	"classroom": "res://images/classroom.png",
	"pen": "res://images/fushimi_pen_story/stationery.png",
}
const LINES := [
	{"speaker": "friend", "text": "喂——/name君，赶紧过来打球。", "background": "classroom"},
	{"speaker": "player", "text": "来了。"},
	{"text": "某节体育课前，我的友人之一A君，热情地邀请我加入球局"},
	{"text": "这样的邀请我自然不会推脱，但或许是兴奋过头的缘故，起身时，我不慎碰掉了邻座的文具盒"},
	{"text": "铅笔、橡皮、直尺，各种文具散落一地，其中有一只粉红色的钢笔格外引人注目", "background": "pen"},
	{"text": "那支钢笔好看极了，笔帽上嵌着一颗颗宝石，在阳光下折射出七色的光芒"},
	{"text": "笔身上贴着几张可爱的卡通鬼的贴纸，尤其是握笔处那几张，看着仍旧很新，看得出来主人极爱这支笔了"},
	{"text": "我心里不仅咯噔一下，要知道钢笔是很娇贵的，这么一摔说不定就坏了"},
	{"text": "加之主人如此爱惜这支笔，我不由得害怕起来"},
	{"text": "因为这支笔的主人，我的同桌，伏见宫夜姬，是这个班上令所有人惧怕的魔头"},
	{"text": "作为班长的她，对待各种事情——无论同学纪律扣分，亦或作业抄袭，可谓毫不留情，令班上众人苦不迭"},
	{"speaker": "player", "text": "对、对不起！", "background": "classroom"},
	{"text": "我慌乱地捡好各种文具，试图做最后的补救"},
	{"speaker": "player", "text": "那个……班长，你没事吧？不对，是你的笔……"},
	{"text": "我战战兢兢地抬起头，看着不知何时已经回到座位旁的伏见宫夜姬。", "mood": FushimiPortraits.Mood.CALM},
	{"text": "她正低垂着眼帘，纤细的手指接过我递过去的那支粉红色钢笔，轻轻拧开笔帽，在随身的草稿纸上划了两下。", "mood": FushimiPortraits.Mood.FOCUSED},
	{"text": "纸面上一片空白，连半点墨迹都没有留下。"},
	{"text": "我的心瞬间沉到了谷底，冷汗顺着额角滑落。完了，果然摔坏了！"},
	{"text": "伏见宫盯着那张白纸看了足足三秒，长长的睫毛微微颤动了一下。紧接着，她抬起头，那双平日里总是毫无波澜的清冷眼眸，此刻正一眨不眨地盯着我，嘴角似乎极其微弱地向上勾起了一个几乎难以察觉的弧度。", "mood": FushimiPortraits.Mood.SMILING},
	{"speaker": "fushimi", "text": "/name 同学，这支笔……是我最喜欢的一支呢。"},
	{"text": "她的声音依旧是那么平静、礼貌，甚至比平时还要轻柔几分，可听在我耳朵里，却无异于死神的宣判。"},
	{"speaker": "player", "text": "对、对不起！我不是故意的！我会赔给你的，或者……或者我一定想办法把它修好！"},
	{"text": "伏见宫轻轻叹了口气，将钢笔放回文具盒里，慢条斯理地拉上拉链，随后坐直了身子，双手交叠放在桌面上。", "mood": FushimiPortraits.Mood.CALM},
	{"speaker": "fushimi", "text": "赔就不用了，毕竟是带有特殊意义的礼物，市面上也买不到一模一样的。既然 /name 同学这么有诚意，那就交给你负责修好吧。放学前还给我就好，做不到的话……", "mood": FushimiPortraits.Mood.EXPLAINING},
	{"text": "她故意拉长了尾音，眼神淡淡地扫过我桌角那本还没写完的练习册，意思不言而喻。", "mood": FushimiPortraits.Mood.FOCUSED},
	{"speaker": "friend", "text": "喂，/name君，还打不打球了？上课铃快响啦！"},
	{"speaker": "player", "text": "不、不打了！你们先去吧，我突然肚子有点痛！"},
	{"text": "我欲哭无泪地朝门口摆了摆手，目送着A君一脸疑惑地跑远，随后如临大敌般坐回座位，双手颤抖着接过了那支“重伤”的粉红钢笔。"},
	{"text": "从那一刻起，这支钢笔就成了我整个下午的噩梦。"},
	{"text": "我哪里懂什么修钢笔的门道，只能凭着一股蛮力与天真的幻想，趁着课间和老师转身的空档，对着它展开了全方位的“抢救”。"},
	{"text": "我先是小心翼翼地用纸巾擦拭着笔尖，生怕上面沾了灰尘堵住出墨口；见没反应，又试着把钢笔倒过来轻轻甩了甩，结果甩得我手腕发酸，笔尖依旧干干净净；最后，我甚至病急乱投医，学着电视里修理工的样子，对着笔尖哈了口热气，在草稿纸上画了一圈又一圈的蚊香。"},
	{"text": "草稿纸被笔尖划得起毛，甚至破了好几个洞，可那支娇贵的粉红钢笔就是半点墨水也吐不出来。"},
	{"speaker": "yue", "text": "/name ，你从刚才开始就一直对着空气画圈圈，到底在干嘛呀？", "yue_mood": YuePortraits.Mood.PUZZLED},
	{"text": "前排的阳奈里转过头，好奇地凑过来瞄了一眼，却被我像护食一样死死捂住了桌面。"},
	{"speaker": "player", "text": "没、没什么！我在练字！练硬笔书法！"},
	{"text": "阳奈里狐疑地眨了眨眼，刚想再问，却被身旁伏见宫投来的一记冷淡视线吓得缩了缩脖子，吐了吐舌头乖乖转了回去。", "yue_mood": YuePortraits.Mood.WINKING},
	{"text": "我偷偷瞥了一眼伏见宫，她正端端正正地看着黑板，侧脸线条精致得像个瓷娃娃，仿佛对我的焦头烂额毫无察觉。可只有我知道，那无形的压迫感正一点点收紧我的喉咙。", "hide_yue": true, "mood": FushimiPortraits.Mood.CALM},
	{"text": "终于，熬到了放学铃声响起。"},
	{"text": "教室里的同学们欢呼着收拾书包，唯独我像霜打的茄子一样，垂头丧气地捧着那支依然写不出字的钢笔，磨磨蹭蹭地转过身。"},
	{"speaker": "player", "text": "那个……伏见宫同学，对不起……我试了一下午，甩也甩了，擦也擦了，它还是不出墨，我真的修不好……"},
	{"text": "我闭上眼睛，已经做好了被记名扣分、甚至被罚抄十遍课文的最坏打算。"},
	{"text": "然而，预想中的斥责并没有落下。"},
	{"text": "头顶上方传来一阵极轻的、像是憋笑憋到极致后不小心漏出来的气音。"},
	{"text": "“噗嗤。”"},
	{"text": "我猛地睁开眼，愣愣地看着眼前的少女。", "mood": FushimiPortraits.Mood.SMILING},
	{"text": "向来不苟言笑、被全班同学私下称为“冰山大魔王”的伏见宫夜姬，此刻正单手掩着唇，眉眼弯弯，眼底闪烁着狡黠而明亮的笑意，连耳尖都染上了一抹淡淡的绯红。"},
	{"speaker": "fushimi", "text": "笨蛋。"},
	{"text": "她轻声吐出两个字，语气里没有半点责怪，反而带着几分难得的娇嗔与促狭。"},
	{"text": "她伸出手指，从我僵硬的手心里抽走那支钢笔，指尖轻轻一旋，直接拧开了笔杆。"},
	{"text": "我瞪大了眼睛凑过去看——只见透明的墨囊里空空如也，连一滴墨水都没有剩下。"},
	{"speaker": "fushimi", "text": "其实在体育课之前，这支笔的墨水就已经用完了，我本来就打算放学回家再换墨囊的。"},
	{"text": "她一边说着，一边将笔杆重新拧好，歪着头看向已经彻底石化的我，嘴角的笑意怎么也压不住。"},
	{"speaker": "fushimi", "text": "谁让你当时一副天塌下来的表情，实在太有趣了……我就忍不住想看看，你到底能折腾到什么时候。"},
	{"speaker": "player", "text": "……所、所以，这笔根本没坏？！"},
	{"speaker": "fushimi", "text": "嗯，完好无损。不过……"},
	{"text": "她将钢笔小心翼翼地放回文具盒，拎起深蓝色的书包站起身，居高临下地看着我，眼底的笑意渐渐收敛，重新换上了那副一本正经的班长模样，只是语气却比平时轻快了许多。", "mood": FushimiPortraits.Mood.CALM},
	{"speaker": "fushimi", "text": "看在你一下午都在努力帮我“修笔”的份上，今天碰掉我文具盒的事情，就一笔勾销吧。明天见，/name 同学。"},
	{"text": "说完，她微微颔首，转身朝着教室门口走去，背影依旧笔挺，只是那轻快的步伐，怎么看都透着几分恶作剧得逞后的愉悦。", "hide_fushimi": true},
	{"text": "我呆呆地坐在座位上，看着桌面上那张被我画满蚊香的草稿纸，半晌才反应过来，脸颊瞬间涨得通红。"},
	{"speaker": "player", "text": "……可恶，原来大魔王也是会捉弄人的啊！"},
]

@onready var fushimi_portrait: TextureRect = $Stage/FushimiPortrait


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func place_portrait() -> void:
	place_portrait_at(yue_portrait, 0.27)
	place_portrait_at(fushimi_portrait, 0.73)


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	if line.has("mood"):
		FushimiPortraits.show_school(fushimi_portrait, line["mood"])
		fushimi_portrait.show()
	if line.has("yue_mood"):
		YuePortraits.show_on(yue_portrait, RoundCalendar.SCHOOL_AGE, line["yue_mood"])
		yue_portrait.show()
	if line.get("hide_yue", false):
		yue_portrait.hide()
	if line.get("hide_fushimi", false):
		fushimi_portrait.hide()
	place_portrait()
	var speaker: String = line.get("speaker", "")
	fushimi_portrait.modulate = Color.WHITE if speaker == "fushimi" else LISTENING_TINT
	yue_portrait.modulate = Color.WHITE if speaker == "yue" else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"friend": return "A君"
		"fushimi": return SocialCharacters.FUSHIMI
		"yue": return SocialCharacters.YUE
	return ""
