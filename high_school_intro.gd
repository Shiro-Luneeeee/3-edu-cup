extends "res://story_dialogue.gd"

enum ClassmateFrame { YUE_POUTING, YUE_SMILING, YUE_WINKING, FUSHIMI_CALM, FUSHIMI_GREETING, FUSHIMI_SMILING }
enum ShirakawaFrame { DEADPAN, FRIENDLY, LAUGHING, STARTLED, DAYDREAMING, FLUSTERED, SERIOUS, TURNED_AWAY }

const SocialCharacters := preload("res://social_characters.gd")
const ART_DIRECTORY := "res://images/high_school_intro"
const BACKGROUNDS := {
	"roster": ART_DIRECTORY + "/roster.png",
	"classroom": "res://images/events/school.png",
}
const LINES := [
	{"text": "开学第一天，按身高和学号排完座位之前，大家得先在公告栏前确认自己的班级。我站在人群外围顺着名单往下找，刚在“一年B班”那一栏看到自己的名字，肩膀就被人从后面轻轻戳了一下。", "background": "roster"},
	{"speaker": "yue", "text": "哎——？/name在B班吗？我跟夜姬都在隔壁A班诶。", "yue": ClassmateFrame.YUE_POUTING},
	{"speaker": "player", "text": "看来初中同班的运气到这儿就用完了。不过A班和B班就隔着一堵墙，下课走两步就能见着。"},
	{"speaker": "yue", "text": "说得也是！那可说好了，午休和放学不准偷偷溜走。", "yue": ClassmateFrame.YUE_SMILING},
	{"text": "正说着，站在公告栏另一侧的女生收起手里的学生手册，朝我们这边走了过来。她把长发规规矩矩地束在脑后，校服领口系得一丝不苟，站在一群还在兴奋叽喳的新生中间，安静得像是从另一幅画里走出来的人。", "fushimi": ClassmateFrame.FUSHIMI_CALM},
	{"speaker": "fushimi", "text": "早安，/name。看来我们不在同一个班级。", "fushimi": ClassmateFrame.FUSHIMI_GREETING},
	{"speaker": "player", "text": "早，伏见宫同学。刚才阳奈里还在说你们俩分到A班去了。"},
	{"speaker": "fushimi", "text": "嗯。虽然不同班，但有什么需要帮忙的地方，随时来A班找我就是了。", "fushimi": ClassmateFrame.FUSHIMI_SMILING},
	{"speaker": "yue", "text": "听见没？我们A班二人组随时欢迎你来串门！", "yue": ClassmateFrame.YUE_WINKING},
	{"text": "预备铃声恰在此时从教学楼里传了出来，清脆地在清晨的空气里荡开。和在楼道口分开走向各自教室的两人道过别，我顺着走廊走进了属于自己的B班教室。"},
	{"text": "开学第一天，按身高和学号排完座位，我面前坐着一个叫白川花雪的女生。听说她是中考全校前几的资优生，我本以为会是个戴着黑框眼镜、说话一板一眼的学霸，结果刚才她上台自我介绍时——", "background": "classroom"},
	{"speaker": "shirakawa", "text": "大家好，我叫白川花雪，喜欢睡觉和发呆，还有……小狗。", "shirakawa": ShirakawaFrame.DEADPAN},
	{"text": "全程不超过五秒，连班主任都愣了一下才反应过来带头鼓掌。回到座位后，她把胳膊支在桌上，单手托着脸颊，指尖无意识地卷着耳边的碎发。柔顺的头发边别着一个圆乎乎的白色毛绒发卡——长着两只亮晶晶的圆眼睛，身体只剩下一个球，连四肢都没有，看着像只缩成团的小兔子。她的视线落在窗外，又像是落在某个不存在的点上，整个人仿佛暂时从这间教室里退了场。", "shirakawa": ShirakawaFrame.DAYDREAMING},
	{"speaker": "player", "text": "那个……同学，你的表。"},
	{"speaker": "shirakawa", "text": "哦，谢谢你呀。", "shirakawa": ShirakawaFrame.FRIENDLY},
	{"text": "空气突然安静了两秒。她没有立刻转回去，而是盯着我右手边的黑色中性笔看了一会儿。", "shirakawa": ShirakawaFrame.DAYDREAMING},
	{"speaker": "shirakawa", "text": "同学，你的笔……看起来好像不太高兴。", "shirakawa": ShirakawaFrame.SERIOUS},
	{"speaker": "player", "text": "……啊？笔怎么会不高兴？"},
	{"speaker": "shirakawa", "text": "因为它被你攥得太紧了，正在喊救命。……算了，当我没说。"},
	{"speaker": "player", "text": "……", "shirakawa": ShirakawaFrame.FLUSTERED},
	{"text": "看我呆住不说话，她就像突然耗尽了全部社交电量似的，“唰”地一下转了回去，只留给我一个毛茸茸的后脑勺，和领口隐约露出一角的金属小狗胸针。我低头看了看自己手里的笔，莫名觉得这位传说中的资优生……好像跟传闻里不太一样。", "shirakawa": ShirakawaFrame.TURNED_AWAY},
]

@onready var fushimi_portrait: TextureRect = $Stage/FushimiPortrait
@onready var shirakawa_portrait: TextureRect = $Stage/ShirakawaPortrait
@onready var classmates_sheet := load(ART_DIRECTORY + "/classmates.png") as Texture2D
@onready var shirakawa_sheet := load(ART_DIRECTORY + "/shirakawa_expressions.png") as Texture2D
@onready var shirakawa_poses := load(ART_DIRECTORY + "/shirakawa_classroom_poses.png") as Texture2D


func lines() -> Array:
	return LINES


func final_button_text() -> String:
	return "开始高中生活  ›"


func place_portrait() -> void:
	place_portrait_at(yue_portrait, 0.27)
	place_portrait_at(fushimi_portrait, 0.73)
	place_portrait_at(shirakawa_portrait, 0.56)


func stage_line(line: Dictionary) -> String:
	if line.has("background"):
		var background: String = line["background"]
		show_background(load(BACKGROUNDS[background]) as Texture2D)
		if background == "classroom":
			yue_portrait.hide()
			fushimi_portrait.hide()
	if line.has("yue"):
		show_frame(yue_portrait, classmates_sheet, line["yue"], Vector2i(3, 2))
	if line.has("fushimi"):
		show_frame(fushimi_portrait, classmates_sheet, line["fushimi"], Vector2i(3, 2))
	if line.has("shirakawa"):
		var frame: int = line["shirakawa"]
		if frame >= ShirakawaFrame.SERIOUS:
			show_frame(shirakawa_portrait, shirakawa_poses, frame - ShirakawaFrame.SERIOUS, Vector2i(2, 1))
		else:
			show_frame(shirakawa_portrait, shirakawa_sheet, frame, Vector2i(3, 2), 12.0)
	place_portrait()
	var speaker: String = line.get("speaker", "")
	yue_portrait.modulate = Color.WHITE if speaker == "yue" else LISTENING_TINT
	fushimi_portrait.modulate = Color.WHITE if speaker == "fushimi" else LISTENING_TINT
	shirakawa_portrait.modulate = Color.WHITE if speaker == "shirakawa" else LISTENING_TINT
	match speaker:
		"player": return PlayerState.player_name
		"yue": return SocialCharacters.YUE
		"fushimi": return SocialCharacters.FUSHIMI
		"shirakawa": return SocialCharacters.SHIRAKAWA
	return ""


@warning_ignore("integer_division")
func show_frame(target: TextureRect, sheet: Texture2D, frame: int, grid: Vector2i, bottom_padding: float = 0.0) -> void:
	var cell_size := sheet.get_size() / Vector2(grid)
	var cell := Vector2(frame % grid.x, frame / grid.x)
	var portrait := AtlasTexture.new()
	portrait.atlas = sheet
	portrait.region = Rect2(cell * cell_size, cell_size - Vector2(0, bottom_padding))
	portrait.filter_clip = true
	target.texture = portrait
	target.show()
