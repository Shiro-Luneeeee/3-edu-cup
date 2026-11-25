extends RefCounted

const RoundCalendar := preload("res://scripts/round_calendar.gd")
const TRIGGER_CHANCE := 0.40
const EFFECT_NAMES := {
	"current_energy": "精力",
	"money": "金钱",
	"intelligence": "智商",
	"emotional_intelligence": "情商",
	"physical_strength": "体魄",
	"upgrade_points": "升级点",
}

const EVENTS := {
	"lost_puzzle": {
		"title": "少了一块",
		"body": "拼图盒上写着二十片。你和家里人各数了一遍，都是十九片。她连拖鞋都翻过来看了，站起来才想起，昨天你们是在地毯上拼的。",
		"setting": "home", "max_age": 6,
		"options": [
			{"title": "沿着地毯边仔细找", "effects": {"intelligence": 10, "current_energy": -3}, "result": "你从地毯底下拽出最后一片。原来那块蓝色是雨靴的一角。"},
			{"title": "留个缺口，一起画一片", "effects": {"emotional_intelligence": 8, "current_energy": -2}, "result": "你们画得都不像盒盖上的图，最后还是把两张都贴在了旁边。"},
			{"title": "把拼图留到下次", "effects": {}, "result": "你把那十九片收回盒里，在盖子上郑重地贴了一张「少一片」。"},
		],
	},
	"paper_wind": {
		"title": "吹跑的纸风车",
		"body": "广场上风很大。一个孩子的纸风车从木棍上脱下来，翻了两个跟头，朝广场另一头滚去。她攥着光秃秃的木棍，一时没反应过来。",
		"setting": "street", "max_age": 6,
		"options": [
			{"title": "跑过去追风车", "effects": {"physical_strength": 12, "current_energy": -4}, "result": "你在花坛边用脚踩住了一片翅膀。拿回去时还有三片能转。"},
			{"title": "陪她去找大人帮忙", "effects": {"emotional_intelligence": 9, "current_energy": -2}, "result": "看门的大叔从花坛里捡回风车，用胶带缠好。她举着风车在风口等了一会儿，翅膀又转起来了。"},
			{"title": "指给她看风车滚去了哪儿", "effects": {}, "result": "你指了指花坛边，她握着那根小木棍跑了过去。"},
		],
	},
	"picture_book": {
		"title": "最后一页先别翻",
		"body": "一本借来的绘本今天要还。故事里那只鸭子已经找了三页雨伞，你还剩最后几页没看。家里人正在门口穿鞋。",
		"setting": "home", "max_age": 6,
		"options": [
			{"title": "趁现在自己读完", "effects": {"intelligence": 12, "current_energy": -4}, "result": "你认不出的字用图猜了过去。最后，鸭子把雨伞借给了比它淋得更湿的青蛙。"},
			{"title": "拿到门口，和家里人轮流读", "effects": {"emotional_intelligence": 8, "current_energy": -2}, "result": "你负责念鸭子说的话。换到青蛙开口时，家里人学错了声音，你笑得差点忘了出门。"},
			{"title": "先合上书，按时还回去", "effects": {}, "result": "你记住了书的封面。下次再借到，就从鸭子站在雨里的那页看起。"},
		],
	},
	"one_broom": {
		"title": "只剩一把扫帚",
		"body": "值日时只找到一把扫帚。另一个值日生把簸箕拎得老高，说要赶紧走，家里答应今天让他挑晚饭。他那一排的桌底还有不少纸屑。",
		"setting": "school", "min_age": 7, "max_age": 18,
		"options": [
			{"title": "连他那一排也扫了", "effects": {"physical_strength": 13, "current_energy": -5}, "result": "你扫到最后一桌，才发现椅子底下还粘着一团湿纸。等你抬头，他已经在门口帮你提起了垃圾袋。"},
			{"title": "商量分工，你扫地，他倒垃圾", "effects": {"emotional_intelligence": 11, "current_energy": -3}, "result": "他说行，不过倒完垃圾得让他最后再检查一遍。他还真从你的第一排捡出一截铅笔芯。"},
			{"title": "扫完自己那排，把扫帚留给他", "effects": {}, "result": "你把扫帚立在讲台边，告诉他纸屑最多的是哪张桌子下面。"},
		],
	},
	"missing_name": {
		"title": "封皮上没写名字",
		"body": "走廊窗台上搁着一本错题本。翻开第一页，题目的旁边写着「又算快了」，字压得纸都快破了。封皮上却没写名字。",
		"setting": "school", "min_age": 7, "max_age": 18,
		"options": [
			{"title": "问问附近几个班，找找失主", "effects": {"emotional_intelligence": 12, "current_energy": -4}, "result": "对方从楼梯口跑回来，接过去先翻到夹着作业的那页，这才想起跟你道谢。"},
			{"title": "记下一种解法，再把本子交给老师", "effects": {"intelligence": 10, "current_energy": -3}, "result": "那道题可以先画线试试。你记下步骤，把本子放到了老师桌上。"},
			{"title": "把本子交到办公室", "effects": {}, "result": "老师替你收下本子，说会在放学前问问。"},
		],
	},
	"loose_clip": {
		"title": "卡住的铁夹",
		"body": "文具角的活页夹合不上了。负责收作业的同学每次一提，就掉两张纸。今天她索性蹲在地上，把最轻的几张夹在膝盖下面。",
		"setting": "school", "min_age": 7, "max_age": 18,
		"options": [
			{"title": "找个长尾夹，把松开的地方固定住", "effects": {"upgrade_points": 18, "current_energy": -4}, "result": "第一只夹子太小，第二只刚好卡住。她提起来抖了两下，纸一张也没掉。"},
			{"title": "陪她把纸张按小组整理好", "effects": {"emotional_intelligence": 9, "current_energy": -2}, "result": "你念名字，她叠纸。中间念错了一个，隔着两排都有人抬头纠正你。"},
			{"title": "告诉老师夹子坏了", "effects": {}, "result": "老师先找了个纸袋，能把这一叠稳稳提过去。"},
		],
	},
	"breakfast_stall": {
		"title": "小店刚开门",
		"body": "街角的小店才拉开半扇门，蒸汽已经冒到屋檐下面。老板看见你往蒸笼里瞧，掀开一条缝，说这笼里有豆沙的。",
		"setting": "street",
		"options": [
			{"title": "买一份热早点", "effects": {"current_energy": 7, "money": -12}, "result": "你隔着纸袋换了两次手。等到了街口，包子终于没那么烫了。"},
			{"title": "留着零钱，回家吃", "effects": {}, "result": "你把钱放回口袋。老板把盖子合上，说晚一点来还有下一笼。"},
		],
	},
	"paper_box": {
		"title": "窗边的旧纸箱",
		"body": "窗边堆着三个空纸箱。最上面那个有一条漂亮的蓝色边框，底下两个已经软了。家里人问你，要留下哪一个做东西。",
		"setting": "home",
		"options": [
			{"title": "捆好纸箱，一起送去回收", "effects": {"money": 10, "physical_strength": 7, "current_energy": -4}, "result": "你抱着扎好的纸箱下楼。箱子比想象的轻，就是太宽，经过门框时得侧着走。"},
			{"title": "裁下蓝色边框，做个收纳盒", "effects": {"upgrade_points": 12, "current_energy": -3}, "result": "你用旧盒盖加固了底。现在那些总滚到桌下的小东西，有地方放了。"},
			{"title": "这次都收起来", "effects": {}, "result": "你把纸箱压平叠好。窗边一下子空出一大块。"},
		],
	},
}


static func draw_event(round_number: int, previous_event: String) -> String:
	if randf() >= TRIGGER_CHANCE:
		return ""
	var current_age := RoundCalendar.age(round_number)
	var candidates: Array[String] = []
	for event_id: String in EVENTS:
		var event: Dictionary = EVENTS[event_id]
		if event_id != previous_event and current_age >= event.get("min_age", current_age) and current_age <= event.get("max_age", current_age):
			candidates.append(event_id)
	return candidates.pick_random() if not candidates.is_empty() else ""


static func describe_effects(effects: Dictionary) -> String:
	var labels := PackedStringArray()
	for effect: String in effects:
		var amount := int(effects[effect])
		labels.append("%s %s%d" % [EFFECT_NAMES[effect], "+" if amount > 0 else "−", absi(amount)])
	return "无数值变化" if labels.is_empty() else "    ·    ".join(labels)
