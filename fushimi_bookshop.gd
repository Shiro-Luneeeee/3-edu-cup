extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const BACKGROUNDS := {
	"hallway": "res://images/middle_school_intro/hallway.png",
	"storefront": "res://images/fushimi_bookshop/storefront.png",
	"reading": "res://images/fushimi_bookshop/reading.png",
	"caught": "res://images/fushimi_bookshop/caught.png",
	"embarrassed": "res://images/fushimi_bookshop/embarrassed.png",
	"smile": "res://images/fushimi_bookshop/smile.png",
}
const LINES := [
	{"text": "初中的社团招新周向来热闹得像一场庙会，整个下午，走廊里都充斥着学长学姐们声嘶力竭的吆喝声和传单漫天飞舞的盛况。", "background": "hallway"},
	{"text": "婉拒了A君拉我去足球部凑人头的邀请后，我好不容易才从喧闹的人群里挤出来，打算顺路去校外那家老旧的旧书店，帮母亲捎一本她托我找的园艺杂志。", "background": "storefront"},
	{"text": "推开旧书店那扇挂着铜铃的木门，店里特有的旧纸张香气与安静瞬间将外界的嘈杂隔绝开来。"},
	{"text": "店里客人很少，我熟门熟路地穿过几排高大的书架，正准备往生活杂志区走，目光却在路过最里侧的儿童文学区时，猛地顿住了。"},
	{"text": "在那个几乎不会有初中生驻足的角落里，一道身姿笔挺的深蓝色水手服背影正安静地站在书架前。", "background": "reading"},
	{"text": "乌黑的长发柔顺地垂在肩后，哪怕只是站在昏暗的书架旁，那份端庄严谨的仪态也让人一眼就能认出来——是刚刚在昨天全票当选了一年B班班长的伏见宫夜姬。"},
	{"text": "可此刻，这位在班上向来只捧着厚重百科全书、连板书都要用直尺比着画的“冰山班长”，手里却正小心翼翼地捧着一本画风极其梦幻的精装版《安徒生童话绘本》。"},
	{"text": "她的神情专注极了，微垂着眼帘，纤细的指尖轻轻抚过书页上烫金的插画，连平时总是紧抿着的唇角，都柔和得近乎梦幻。"},
	{"speaker": "player", "text": "……伏见宫同学？"},
	{"text": "我一时没忍住，下意识地轻声喊了一句。"},
	{"text": "话一出口我就后悔了，但已经来不及了。"},
	{"text": "空气仿佛在那一瞬间凝固了。"},
	{"text": "伏见宫的肩膀极其轻微地颤动了一下，随后以一种近乎机械的慢动作合上绘本，缓缓转过身来。", "background": "caught"},
	{"text": "当看清站在走廊尽头的人是我时，那双平日里总是清冷如水、波澜不惊的眼眸，罕见地睁大了几分，白皙的脸颊以肉眼可见的速度泛起了一层薄红，一直蔓延到了耳根。"},
	{"speaker": "fushimi", "text": "/name 同学……？你怎么会在这里？"},
	{"text": "她的声音依旧努力维持着平时的镇定，可握着书脊的手指却微微收紧，甚至下意识地把那本印着公主与小精灵的绘本往身后藏了藏。"},
	{"speaker": "player", "text": "我、我来帮我妈买园艺杂志……倒是伏见宫同学，你刚才看的难道是……"},
	{"text": "我的视线不受控制地往她身后瞄了一眼，露出的半截书角上，正印着一只戴着皇冠的小青蛙。"},
	{"text": "伏见宫像是被踩中了尾巴的猫一样，耳尖瞬间红得滴血，深吸了一口气，强行摆出班长的威严姿态，只是眼神却有些飘忽，不敢直视我的眼睛。", "background": "embarrassed"},
	{"speaker": "fushimi", "text": "……只是帮家里的亲戚挑选生日礼物而已。对，就是这样。"},
	{"speaker": "player", "text": "原来如此，还真是细心啊，连插画都要一页一页仔细检查……"},
	{"text": "我憋着笑，故意顺着她的话点了点头，目光却忍不住在她略显慌乱的脸上多停留了两秒。原来平时高高在上的大魔王，私底下竟然喜欢看这种少女心十足的童话书。"},
	{"text": "似乎是察觉到了我眼底那点藏不住的笑意，伏见宫微微抿了抿唇，神情几经挣扎，最终像是放弃了挣扎般轻轻叹了口气，肩膀也随之放松了下来。"},
	{"text": "她慢吞吞地把那本绘本重新拿到身前，低着头盯着封面上的烫金花纹，声音比平时轻了好几个度，带着几分难得的局促与妥协。"},
	{"speaker": "fushimi", "text": "……算了，骗不过你。"},
	{"speaker": "player", "text": "欸？真的不是给亲戚买的？"},
	{"speaker": "fushimi", "text": "嗯。我只是……从小就喜欢看这些故事而已。"},
	{"text": "她抬起眼帘飞快地瞥了我一眼，眼神里透着一丝与平时截然不同的青涩与坦率，像是在守护着自己最珍视的宝物。"},
	{"speaker": "fushimi", "text": "毕竟现实里的规则和条框已经够多了，偶尔看看这些不讲道理的魔法和奇迹，心情会放松很多。不过——"},
	{"text": "她话锋一转，重新抬起下巴，那双清亮的眸子直直地锁定了我，语气里又恢复了几分熟悉的压迫感，只是这次怎么听都像是在虚张声势。", "background": "caught"},
	{"speaker": "fushimi", "text": "这件事，要是被班上其他人知道了，尤其是月侧同学……/name 同学，你应该知道后果的吧？"},
	{"speaker": "player", "text": "绝对保密！我发誓，今天我根本没来过旧书店，也绝对没见过什么童话绘本！"},
	{"text": "我立刻举起三根手指，摆出一副忠心耿耿的模样。"},
	{"text": "看着我这副如临大敌的架势，伏见宫紧绷的嘴角终于忍不住微微向上弯起，眼底漾开了一层柔和而明亮的笑意，像春日里融化的冰雪。", "background": "smile"},
	{"speaker": "fushimi", "text": "这还差不多。作为封口费……"},
	{"text": "她微微侧过身，让出半个书架的位置，指尖轻轻点了点旁边那本《格林童话全集》，偏过头看向我，耳尖的红晕还未完全褪去，语气却已经恢复了往日的从容。"},
	{"speaker": "fushimi", "text": "既然来了，就陪我看一会儿再走吧。顺便，把你上周借走还没还的课堂笔记一并交代清楚。"},
	{"speaker": "player", "text": "啊……这个就不用顺便了吧！"},
	{"text": "夕阳透过旧书店的玻璃窗洒进来，在满地书影间拉出两道长长的影子。我一边哀嚎着翻找书包，一边偷偷看着身旁重新低头翻开绘本的少女，心里突然觉得，能和她共享这个只有两个人的小秘密，似乎还挺不赖的。", "background": "reading"},
]


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"fushimi": return SocialCharacters.FUSHIMI
	return ""
