extends RefCounted

const DIRECTORY := "res://images/card"
const CARDS := {
	0: ["预习", 0], 1: ["解题", 0], 2: ["深呼吸", 0],
	3: ["认真听讲", 1], 4: ["课间休息", 1], 5: ["合作", 1],
	6: ["熬夜突击", 2], 7: ["押题", 2], 8: ["调整心态", 2], 9: ["通宵", 3],
	10: ["创口贴", 0], 11: ["临时抱佛脚", 0], 12: ["换换脑子", 0],
	13: ["小测验", 1], 14: ["留到明天", 1], 15: ["午休", 2],
	16: ["模拟考", 2], 17: ["请假", 2], 18: ["期中总复习", 3],
	19: ["暑假", 3], 20: ["新学期", 3],
}
enum Upgrade { INCREASE, DECREASE, BOOST_PROGRESS, BOOST_DEFENSE }

const UPGRADE_COST := 100
const NUMBER_NAMES := {
	"draw": "抽牌张数",
	"progress": "进度", "block": "格挡", "heal": "回复心态", "health_change": "心态变化",
	"health_set": "设定心态", "duration": "持续回合",
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
}


static func available_ids() -> Array[int]:
	var ids: Array[int] = []
	for file in ResourceLoader.list_directory(DIRECTORY):
		var stem := file.get_basename()
		if file.get_extension() == "png" and stem.is_valid_int() and CARDS.has(stem.to_int()):
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
		"health_change": return -2147483647
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
			if allowed.has("progress"):
				updated["progress"] = boosted_number(int(updated["progress"]))
		Upgrade.BOOST_DEFENSE:
			for defense_field in ["block", "heal", "health_set", "health_change"]:
				if allowed.has(defense_field) and int(updated[defense_field]) > 0:
					updated[defense_field] = boosted_number(int(updated[defense_field]))
	return updated


@warning_ignore("integer_division")
static func boosted_number(value: int) -> int:
	return value + value / 5


static func texture(card_id: int) -> Texture2D:
	return load("%s/%d.png" % [DIRECTORY, card_id]) as Texture2D


static func exhausts_on_play(card_id: int) -> bool:
	return card_id == 11
