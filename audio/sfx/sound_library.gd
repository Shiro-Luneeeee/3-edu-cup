extends RefCounted

const CATALOG_PATH := "res://audio/sfx/sounds.json"


static func catalog() -> Dictionary:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("Cannot open sound catalog: %s" % CATALOG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("Invalid sound catalog: %s" % CATALOG_PATH)
		return {}
	return parsed


static func configure(player: AudioStreamPlayer, key: String) -> void:
	var entry: Dictionary = catalog().get(key, {})
	player.stream = load(str(entry.get("path", ""))) as AudioStream
	player.volume_db = float(entry.get("volume_db", 0.0))
