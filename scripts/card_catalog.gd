extends RefCounted

const DIRECTORY := "res://images/card"
const YUE_DIRECTORY := "res://images/card_yue"
const YUE_FIRST_CARD := 100
const YUE_GOLDFISH_CARD := 101
const YUE_EMPTY_FISHBOWL_CARD := 102
const YUE_OATH_CARD := 103
const YUE_FINAL_PROMISE_CARD := 104
const FUSHIMI_DIRECTORY := "res://images/card_fu"
const FUSHIMI_PEN_CARD := 200
const FUSHIMI_TUTORING_CARD := 201
const FUSHIMI_NIGHT_WALK_CARD := 202
const FUSHIMI_TOGETHER_CARD := 203
const FUSHIMI_LAST_BATTLE_CARD := 204
const SHIRAKAWA_DIRECTORY := "res://images/card_bai"
const SHIRAKAWA_GAME_CARD := 300
const SHIRAKAWA_FAVOR_CARD := 301
const SHIRAKAWA_PUPPY_CARD := 302
const SHIRAKAWA_OSMANTHUS_CARD := 303
const SHIRAKAWA_SNOW_CARD := 304
# Card numbers determine artwork and chapter order. The IDs above are stored in saves.
const FUSHIMI_CARDS_BY_NUMBER := [
	FUSHIMI_PEN_CARD, FUSHIMI_TUTORING_CARD, FUSHIMI_TOGETHER_CARD,
	FUSHIMI_NIGHT_WALK_CARD, FUSHIMI_LAST_BATTLE_CARD,
]
const CARDS := {
	0: ["预习", 0], 1: ["解题", 0], 2: ["深呼吸", 0],
	3: ["认真听讲", 1], 4: ["课间休息", 1], 5: ["合作", 1],
	6: ["熬夜突击", 2], 7: ["押题", 2], 8: ["调整心态", 2], 9: ["通宵", 3],
	10: ["创口贴", 0], 11: ["临时抱佛脚", 0], 12: ["换换脑子", 0],
	13: ["小测验", 1], 14: ["留到明天", 1], 15: ["午休", 2],
	16: ["模拟考", 2], 17: ["请假", 2], 18: ["期中总复习", 3],
	19: ["暑假", 3], 20: ["新学期", 3],
	21: ["咖啡", 1], 22: ["挣扎", 2], 23: ["孤注一掷", 3], 24: ["温故", 1],
	25: ["知新", 1], 26: ["小憩", 0], 27: ["挑灯奋战", 1],
	YUE_FIRST_CARD: ["公园的约定", 3],
	YUE_GOLDFISH_CARD: ["阳奈里的金鱼", 1],
	YUE_EMPTY_FISHBOWL_CARD: ["空鱼缸", 0],
	YUE_OATH_CARD: ["阳奈里的誓约", 1],
	YUE_FINAL_PROMISE_CARD: ["高考前的约定", 0],
	FUSHIMI_PEN_CARD: ["夜姬的钢笔", 5],
	FUSHIMI_TUTORING_CARD: ["一起努力", 0],
	FUSHIMI_TOGETHER_CARD: ["同舟共济", 0],
	FUSHIMI_NIGHT_WALK_CARD: ["深夜的同行", 2],
	FUSHIMI_LAST_BATTLE_CARD: ["最后一次战役", 3],
	SHIRAKAWA_GAME_CARD: ["买刀买马", 1],
	SHIRAKAWA_FAVOR_CARD: ["花雪的偏爱", 0],
	SHIRAKAWA_PUPPY_CARD: ["小毛球的约定", 2],
	SHIRAKAWA_OSMANTHUS_CARD: ["不枯萎的桂花", 3],
	SHIRAKAWA_SNOW_CARD: ["温暖的初雪", 15],
}
enum Upgrade { INCREASE, DECREASE, BOOST_PROGRESS, BOOST_DEFENSE }

const UPGRADE_COST := 100
const NUMBER_NAMES := {
	"draw": "抽牌张数",
	"progress": "进度", "block": "格挡", "heal": "回复心态", "health_change": "心态变化",
	"health_set": "设定心态", "duration": "持续回合",
	"energy_gain": "获得费用", "next_energy_gain": "下回合获得费用",
	"next_energy_change": "下回合费用变化", "starting_energy_gain": "每回合额外费用",
	"health_per_hand": "每张手牌改变心态",
	"recover_max_cost": "可取回卡牌的最高花费",
	"cost_reduction": "降低卡牌花费",
	"discard_progress": "弃牌时提供的进度",
	"progress_per_discard": "每次弃牌增加的进度",
}
const CARD_NUMBERS := {
	0: {"draw": 1}, 1: {"progress": 3}, 2: {"block": 3}, 3: {"progress": 6},
	4: {"heal": 4, "block": 3}, 5: {"duration": 2}, 6: {"health_change": -4, "progress": 24},
	7: {"pick": 1, "progress": 13}, 8: {"heal": 4, "block": 3},
	9: {"duration": 2, "progress": 36}, 10: {"heal": 2}, 11: {"progress": 6},
	12: {"discard": 1, "draw": 2}, 13: {"progress": 12, "draw": 1, "discard": 1},
	14: {"duration": 2}, 15: {"heal": 8, "draw": 1},
	16: {"progress": 12, "draw": 1, "block": 3}, 17: {"block": 2},
	18: {"progress": 15, "draw": 2}, 19: {"health_set": 20}, 20: {"draw": 6},
	21: {"energy_gain": 3, "next_energy_change": -1}, 22: {"starting_energy_gain": 1},
	23: {"next_energy_gain": 5, "duration": 2}, 24: {}, 25: {"draw": 1},
	26: {"energy_gain": 2}, 27: {"health_per_hand": -1, "draw": 3},
	YUE_FIRST_CARD: {"duration": 2},
	YUE_GOLDFISH_CARD: {"starting_energy_gain": 1},
	YUE_EMPTY_FISHBOWL_CARD: {"recover_max_cost": 0},
	YUE_OATH_CARD: {"cost_reduction": 1},
	YUE_FINAL_PROMISE_CARD: {},
	FUSHIMI_PEN_CARD: {"progress": 80, "cost_reduction": 1},
	FUSHIMI_TUTORING_CARD: {},
	FUSHIMI_TOGETHER_CARD: {},
	FUSHIMI_NIGHT_WALK_CARD: {"progress": 20, "discard_progress": 10},
	FUSHIMI_LAST_BATTLE_CARD: {"progress": 20, "progress_per_discard": 10},
	SHIRAKAWA_GAME_CARD: {"mill": 5},
	SHIRAKAWA_FAVOR_CARD: {"minimum_cost": 2},
	SHIRAKAWA_PUPPY_CARD: {"turn_end_progress_per_card": 2},
	SHIRAKAWA_OSMANTHUS_CARD: {"cost_reduction": 1},
	SHIRAKAWA_SNOW_CARD: {},
}
# Regions around Arabic numerals in the original effect text, in card texture pixels.
const NUMBER_REGIONS := {
	1: {"progress": Rect2i(230, 1029, 68, 67)},
	2: {"block": Rect2i(231, 1028, 67, 67)},
	3: {"progress": Rect2i(228, 1029, 69, 66)},
	4: {"heal": Rect2i(229, 1028, 69, 66), "block": Rect2i(230, 1119, 68, 67)},
	6: {"health_change": Rect2i(358, 1023, 89, 66), "progress": Rect2i(230, 1112, 113, 67)},
	7: {"progress": Rect2i(230, 1095, 111, 66)},
	8: {"heal": Rect2i(227, 1106, 67, 64), "block": Rect2i(228, 1191, 68, 66)},
	9: {"progress": Rect2i(232, 1194, 123, 68)},
	10: {"heal": Rect2i(247, 1050, 67, 68)},
	11: {"progress": Rect2i(231, 1012, 59, 66)},
	13: {"progress": Rect2i(230, 1023, 95, 62)},
	14: {"duration": Rect2i(226, 1097, 78, 67)},
	15: {"heal": Rect2i(233, 1012, 63, 67)},
	16: {"progress": Rect2i(228, 1015, 96, 62), "block": Rect2i(232, 1188, 66, 67)},
	17: {"block": Rect2i(219, 1088, 74, 67)},
	18: {"progress": Rect2i(231, 1023, 94, 62), "draw": Rect2i(169, 1107, 71, 63)},
	19: {"health_set": Rect2i(592, 1019, 106, 65)},
	20: {"draw": Rect2i(228, 1099, 74, 70)},
	21: {"energy_gain": Rect2i(227, 1012, 67, 64), "next_energy_change": Rect2i(232, 1186, 99, 63)},
	22: {"starting_energy_gain": Rect2i(418, 1184, 109, 61)},
	23: {"next_energy_gain": Rect2i(227, 1086, 64, 62), "duration": Rect2i(232, 1251, 64, 62)},
	26: {"energy_gain": Rect2i(229, 1012, 64, 62)},
	27: {"health_per_hand": Rect2i(405, 1097, 93, 61), "draw": Rect2i(172, 1185, 64, 62)},
	YUE_FIRST_CARD: {"duration": Rect2i(219, 1092, 64, 68)},
	YUE_GOLDFISH_CARD: {"starting_energy_gain": Rect2i(343, 1174, 44, 69)},
	YUE_EMPTY_FISHBOWL_CARD: {"recover_max_cost": Rect2i(391, 1092, 51, 70)},
	YUE_OATH_CARD: {"cost_reduction": Rect2i(662, 1014, 38, 63)},
	FUSHIMI_PEN_CARD: {"progress": Rect2i(270, 934, 92, 65), "cost_reduction": Rect2i(534, 1043, 62, 55)},
	FUSHIMI_NIGHT_WALK_CARD: {"progress": Rect2i(262, 934, 93, 69), "discard_progress": Rect2i(507, 1019, 90, 68)},
	FUSHIMI_LAST_BATTLE_CARD: {"progress": Rect2i(269, 945, 95, 66), "progress_per_discard": Rect2i(815, 1109, 128, 67)},
}


static func available_ids() -> Array[int]:
	var ids: Array[int] = []
	for file in ResourceLoader.list_directory(DIRECTORY):
		var stem := file.get_basename()
		if file.get_extension() == "png" and stem.is_valid_int() and stem.to_int() < YUE_FIRST_CARD and CARDS.has(stem.to_int()):
			ids.append(stem.to_int())
	ids.sort()
	return ids


static func card_name(card_id: int) -> String:
	return CARDS[card_id][0]


static func cost(card_id: int) -> int:
	return CARDS[card_id][1]


static func numbers(card_id: int) -> Dictionary:
	return CARD_NUMBERS[card_id].duplicate()


static func number_regions(card_id: int) -> Dictionary:
	return NUMBER_REGIONS.get(card_id, {})


static func minimum_number(field: String) -> int:
	match field:
		"duration", "health_set": return 1
		"health_change", "health_per_hand", "next_energy_change": return -2147483647
	return 0


static func upgraded_numbers(card_id: int, values: Dictionary, operation: int, field: String) -> Dictionary:
	var updated := values.duplicate()
	var allowed := number_regions(card_id)
	match operation:
		Upgrade.INCREASE, Upgrade.DECREASE:
			if allowed.has(field):
				var delta := 1 if operation == Upgrade.INCREASE else -1
				updated[field] = maxi(minimum_number(field), int(updated[field]) + delta)
		Upgrade.BOOST_PROGRESS:
			for progress_field in ["progress", "discard_progress", "progress_per_discard"]:
				if allowed.has(progress_field):
					updated[progress_field] = boosted_number(int(updated[progress_field]))
		Upgrade.BOOST_DEFENSE:
			for defense_field in ["block", "heal", "health_set", "health_change", "health_per_hand"]:
				if allowed.has(defense_field) and int(updated[defense_field]) > 0:
					updated[defense_field] = boosted_number(int(updated[defense_field]))
	return updated


@warning_ignore("integer_division")
static func boosted_number(value: int) -> int:
	return value + value / 5


static func texture(card_id: int) -> Texture2D:
	if card_id >= SHIRAKAWA_GAME_CARD:
		return load("%s/%d.png" % [SHIRAKAWA_DIRECTORY, card_id - SHIRAKAWA_GAME_CARD]) as Texture2D
	if card_id >= FUSHIMI_PEN_CARD:
		var number := FUSHIMI_CARDS_BY_NUMBER.find(card_id)
		return load("%s/%d.png" % [FUSHIMI_DIRECTORY, number]) as Texture2D
	if card_id >= YUE_FIRST_CARD:
		return load("%s/%d.png" % [YUE_DIRECTORY, card_id - YUE_FIRST_CARD]) as Texture2D
	return load("%s/%d.png" % [DIRECTORY, card_id]) as Texture2D


static func yue_story_card(chapter_index: int) -> int:
	var card_id := YUE_FIRST_CARD + chapter_index
	return card_id if chapter_index >= 0 and card_id <= YUE_FINAL_PROMISE_CARD else -1


static func fushimi_story_card(chapter_index: int) -> int:
	return FUSHIMI_CARDS_BY_NUMBER[chapter_index] if chapter_index >= 0 and chapter_index < FUSHIMI_CARDS_BY_NUMBER.size() else -1


static func shirakawa_story_card(chapter_index: int) -> int:
	var card_id := SHIRAKAWA_GAME_CARD + chapter_index
	return card_id if chapter_index >= 0 and card_id <= SHIRAKAWA_SNOW_CARD else -1


static func exhausts_on_play(card_id: int) -> bool:
	return card_id == 11 or card_id == 26
