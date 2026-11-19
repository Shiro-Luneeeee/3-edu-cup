extends Node

enum PageMode { LOAD, SAVE_AND_EXIT }

const SLOT_COUNT := 3
const SCHEMA_VERSION := 1
const SAVE_DIRECTORY := "user://saves"
const SAVE_PAGE_SCENE := "res://save_page.tscn"

var page_mode := PageMode.LOAD


func open_load_page() -> void:
	page_mode = PageMode.LOAD
	SceneFade.change_to(SAVE_PAGE_SCENE)


func open_save_page() -> void:
	page_mode = PageMode.SAVE_AND_EXIT
	SceneFade.change_to(SAVE_PAGE_SCENE)


func has_any_save() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if not read_slot(slot).is_empty():
			return true
	return false


func read_slot(slot: int) -> Dictionary:
	if not is_valid_slot(slot):
		return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var data: Dictionary = parsed
	if int(data.get("schema_version", 0)) != SCHEMA_VERSION:
		return {}
	if not data.get("player") is Dictionary or not data.get("study") is Dictionary:
		return {}
	return data


func save_slot(slot: int) -> bool:
	if not is_valid_slot(slot):
		return false
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY))
	if directory_error != OK:
		push_error("Could not create save directory: %s" % error_string(directory_error))
		return false
	var now := int(Time.get_unix_time_from_system())
	var old_save := read_slot(slot)
	var record := {
		"schema_version": SCHEMA_VERSION,
		"created_unix": int(old_save.get("created_unix", now)),
		"saved_unix": now,
		"saved_local": local_time_string(),
		"player": PlayerState.make_snapshot(),
		"study": StudyProgress.make_snapshot(),
	}
	var file := FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		push_error("Could not write save slot %d: %s" % [slot, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(JSON.stringify(record, "\t"))
	file.flush()
	return file.get_error() == OK


func load_slot(slot: int) -> bool:
	var data := read_slot(slot)
	if data.is_empty():
		return false
	PlayerState.restore_snapshot(data["player"])
	StudyProgress.restore_snapshot(data["study"])
	return true


func delete_slot(slot: int) -> bool:
	if not is_valid_slot(slot) or not FileAccess.file_exists(slot_path(slot)):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot))) == OK


func age_text(data: Dictionary) -> String:
	var seconds := maxi(0, int(Time.get_unix_time_from_system()) - int(data.get("created_unix", 0)))
	var days := floori(float(seconds) / 86400.0)
	var hours := floori(float(seconds % 86400) / 3600.0)
	var minutes := floori(float(seconds % 3600) / 60.0)
	if days > 0:
		return "%d天 %d小时" % [days, hours]
	if hours > 0:
		return "%d小时 %d分钟" % [hours, minutes]
	if minutes > 0:
		return "%d分钟" % minutes
	return "刚建立"


func local_time_string() -> String:
	var current := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [current.year, current.month, current.day, current.hour, current.minute]


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [SAVE_DIRECTORY, slot]
