extends "res://story_dialogue.gd"

const SocialCharacters := preload("res://social_characters.gd")
const BACKGROUNDS := {
	"school": "res://images/classroom.png",
	"park": "res://images/yue_goldfish/sunset.png",
	"smile": "res://images/yue_confession/smile.jpg",
	"pouting": "res://images/yue_confession/pouting.png",
	"attentive": "res://images/yue_confession/attentive.png",
	"surprised": "res://images/yue_confession/surprised.jpg",
	"shy": "res://images/yue_confession/shy.png",
	"reciprocal": "res://images/yue_confession/reciprocal.png",
	"playful": "res://images/yue_confession/playful.png",
}
const LINES := [
	{"text": "升入初中后，校服换成了深色系，课业也渐渐压得人喘不过气，我和阳奈里之间那种小时候毫无顾忌的疯闹，不知从什么时候起少了不少。", "background": "school"},
	{"text": "偶尔在教学楼走廊碰见，大多也只是匆匆点个头，或者在放学路上并肩走一段，各自揣着各自的小心思。"},
	{"text": "直到一个晚霞满天的傍晚，我刚做完值日从学校出来，顺路拐进了小区公园。", "background": "park"},
	{"text": "老树下的那片草地安静极了，晚风吹过树梢，带起一阵细碎的沙沙声。"},
	{"text": "我走到长椅边坐下，正望着远处池塘的水面发呆，身后忽然传来熟悉的脚步声。"},
	{"speaker": "yue", "text": "/name ，你怎么又一个人坐在这里发呆呀？"},
	{"text": "阳奈里走了过来，手里抱着一叠刚发下来的试卷，校服领口在晚风里微微晃动。", "background": "smile"},
	{"speaker": "player", "text": "刚忙完，顺便过来吹吹风。你呢，今天怎么这么晚？"},
	{"speaker": "yue", "text": "被数学老师留下来订正错题了呗，头都要炸啦。"},
	{"text": "她说着，顺势在我旁边坐下，把试卷往膝盖上一放，叹了口气，可转头看向我时，嘴角却又悄悄弯了起来。"},
	{"speaker": "yue", "text": "不过说起来，升上初中以后，感觉我们好像变客气好多呢。"},
	{"speaker": "player", "text": "有吗？"},
	{"speaker": "yue", "text": "当然有！以前在池塘边的时候，你还会为了证明自己不是胆小鬼，差点踩进泥里呢。"},
	{"text": "她歪着头看我，琥珀色的眼睛里闪着一点怀念，又带着几分试探。"},
	{"speaker": "yue", "text": "现在倒好，见了面连拌嘴都像在走流程一样，一点都不好玩了。", "background": "pouting"},
	{"text": "夕阳的余晖把树影拉得很长很长，远处公园的路灯次第亮起，暖黄的光晕落在草地上。", "camera_move": true},
	{"text": "我看着身旁这个从小一起长大的女孩，心里忽然涌起一股说不出来的冲动。"},
	{"text": "从第一次在池塘边拉钩，到送她那条红金鱼，再到后来一起埋葬它——很多事情都在时间里悄悄改变了模样，唯独她在我心里的位置，不仅没有变浅，反而越来越深。"},
	{"speaker": "player", "text": "阳奈里。"},
	{"speaker": "yue", "text": "嗯？怎么突然这么正经？", "background": "attentive"},
	{"text": "她微微一愣，下意识地坐直了身子。"},
	{"speaker": "player", "text": "其实……我一直都很喜欢你。"},
	{"text": "话出口的那一刻，心跳突然漏了一拍，可既然开了口，我也就不再躲闪，直直地看着她的眼睛。", "background": "surprised"},
	{"speaker": "player", "text": "不是小时候那种一起玩、一起看鱼的喜欢，是想一直陪着你，想成为对你来说特别的人的那种喜欢。"},
	{"text": "空气仿佛在这一刻安静了下来，只剩下晚风拂过树叶的声音。"},
	{"text": "阳奈里瞪大了眼睛，手里的试卷差点滑落，脸颊以肉眼可见的速度红了起来，连耳根都染上了一层浅浅的粉色。"},
	{"speaker": "yue", "text": "你……你突然说这个干嘛呀， /name ……"},
	{"text": "她的声音小得几乎听不见，手指紧张地捏着试卷的边缘，眼神闪烁着，却没有移开。"},
	{"speaker": "player", "text": "我知道现在说可能有点突然，你不用立刻给我答复，我只是不想再瞒着你了。"},
	{"text": "我垂下眼帘，嘴角勉强扯出一个有些紧张却无比认真的笑意。"},
	{"speaker": "yue", "text": "……笨蛋。", "background": "shy"},
	{"speaker": "player", "text": "欸？"},
	{"speaker": "yue", "text": "我说你是笨蛋啦！这种事情……哪有让人等那么久的呀。"},
	{"text": "她抬起头，眼眶微微泛着光，虽然还在害羞地别过脸，却鼓足勇气小声补了一句。", "background": "reciprocal"},
	{"speaker": "yue", "text": "明明……我也早就喜欢 /name 了……从以前就一直很喜欢。"},
	{"text": "晚风轻柔地吹过，路灯的光晕把我们笼罩在同一个角落里。我看着眼前这个红着脸却无比坦率的女孩，心里的紧张渐渐化开，伸出手轻轻牵住了她的手。"},
	{"speaker": "player", "text": "那以后，也请多多指教了，阳奈里。"},
	{"text": "听到那句“明明我也早就喜欢 /name 了”时，我感觉连晚风都停顿了一瞬。"},
	{"text": "公园路灯的暖光洒在草地上，阳奈里垂着眼睫，刚才还像只炸毛小猫一样闹别扭的她，此刻却安静得像个刚把秘密交出去的小孩。"},
	{"speaker": "player", "text": "那……我们现在算是在一起了吗？"},
	{"text": "我握着她的手，指尖能清晰地感受到她微微发烫的温度，还有那点藏不住的紧张。"},
	{"speaker": "yue", "text": "唔……你说呢？"},
	{"text": "她没有立刻抽回手，反而轻轻反扣住了我的手指，嘴角悄悄扬起一个带着几分得意又有点羞涩的弧度。", "background": "smile"},
	{"speaker": "yue", "text": "既然都已经把话说开了，那以后放学一起回家、周末一起出来玩，可都是理所当然的哦。"},
	{"speaker": "player", "text": "当然，求之不得。"},
	{"text": "远处的池塘水面泛起细碎的波光，映着天边最后一抹橘粉色的晚霞。", "background": "park", "camera_move": true},
	{"text": "从最初那个在池塘边拉钩的午后，到那条早已长眠在老树下的红金鱼，再到如今并肩站在路灯下的我们，有些心意虽然来得比想象中晚了一点，却偏偏在最恰当的时刻落了地。"},
	{"speaker": "yue", "text": "不过……以后周末一起出来玩的时候，可不许光顾着看书或者发呆哦。"},
	{"text": "她忽然凑近了一点，琥珀色的眸子亮晶晶地眨了眨，嘴角带着几分狡黠的笑意。", "background": "playful"},
	{"speaker": "yue", "text": "要是敢敷衍我，我可是会生气的。"},
	{"speaker": "player", "text": "怎么会，陪女朋友出来玩，我肯定打起十二分精神。"},
	{"speaker": "yue", "text": "哼，算你识相。"},
	{"text": "她嘴上逞强着，脚步却轻快地往前迈了半步，拉着我的手晃了晃。"},
	{"speaker": "yue", "text": "走啦， /name ！再不回去，晚饭都要凉了。"},
	{"speaker": "player", "text": "嗯，走吧。"},
	{"text": "我们并肩走过草地，身后被路灯拉长的影子渐渐靠在了一起，在初夏的晚风里，走向属于我们的崭新日常。", "background": "park"},
]


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "查看专属卡  ›"


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		show_background(load(BACKGROUNDS[line["background"]]) as Texture2D)
	if line.get("camera_move", false):
		shake_stage(0.35)
	match line.get("speaker", ""):
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
	return ""
