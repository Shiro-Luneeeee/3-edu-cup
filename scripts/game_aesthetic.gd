extends RefCounted

const GAMES := [
	preload("res://data/games/univerthm.tres"),
	preload("res://data/games/phantom_sonnet.tres"),
	preload("res://data/games/pale_myth_heart_sky.tres"),
]
const FULL_GAIN_PLAYS := 3
const TARGET_POINTS := 500


static func target_points() -> int:
	return TARGET_POINTS


static func contains_game(game_id: String) -> bool:
	for game in GAMES:
		if game.id == game_id:
			return true
	return false


static func gain(price: int, completed_plays: int) -> int:
	if price <= 0:
		return 0
	if completed_plays < FULL_GAIN_PLAYS:
		return price
	return maxi(1, roundi(float(price) * FULL_GAIN_PLAYS / (completed_plays + 1)))
