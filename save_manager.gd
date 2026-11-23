extends Node

enum PageMode { LOAD, SAVE_AND_EXIT }

const SLOT_COUNT := 3
const SCHEMA_VERSION := 1
const SAVE_DIRECTORY := "user://saves"
const RELEASE_SAVE_DIRECTORY := "user://release_saves"
const SAVE_PAGE_SCENE := "res://save_page.tscn"
const MAIN_MENU_SCENE := "res://main_menu.tscn"

var page_mode := PageMode.LOAD
var carried_music: AudioStreamPlayer
var music_origin_scene := ""
var keep_music_for_scene_change := false
var scene_playlist: Array[AudioStreamMP3] = []
var playlist_index := 0
var play_seconds := 0.0


func _process(delta: float) -> void:
	var current := get_tree().current_scene
	if current != null and current.scene_file_path not in [MAIN_MENU_SCENE, SAVE_PAGE_SCENE]:
		play_seconds += delta


func start_new_game() -> void:
	play_seconds = 0.0


func open_load_page() -> void:
	page_mode = PageMode.LOAD
	keep_music_for_scene_change = true
	SceneFade.change_to(SAVE_PAGE_SCENE)


func open_save_page() -> void:
	page_mode = PageMode.SAVE_AND_EXIT
	keep_music_for_scene_change = true
	SceneFade.change_to(SAVE_PAGE_SCENE)


func keep_scene_music_on_exit() -> void:
	keep_music_for_scene_change = true


func use_scene_music(scene_path: String, scene_music: AudioStreamPlayer) -> AudioStreamPlayer:
	keep_music_for_scene_change = false
	if is_instance_valid(carried_music):
		if music_origin_scene == scene_path:
			scene_music.queue_free()
			return carried_music
		carried_music.stop()
		carried_music.queue_free()
	scene_playlist.clear()
	playlist_index = 0
	scene_music.reparent(self)
	var music_stream := scene_music.stream.duplicate() as AudioStreamMP3
	music_stream.loop = true
	scene_music.stream = music_stream
	scene_music.play()
	carried_music = scene_music
	music_origin_scene = scene_path
	return scene_music


func use_scene_playlist(scene_path: String, scene_music: AudioStreamPlayer, tracks: Array) -> AudioStreamPlayer:
	keep_music_for_scene_change = false
	if is_instance_valid(carried_music):
		if music_origin_scene == scene_path:
			scene_music.queue_free()
			return carried_music
		carried_music.stop()
		carried_music.queue_free()
	scene_playlist.clear()
	for track in tracks:
		if track is AudioStreamMP3:
			scene_playlist.append(track)
	playlist_index = 0
	scene_music.reparent(self)
	carried_music = scene_music
	music_origin_scene = scene_path
	scene_music.finished.connect(_advance_scene_playlist)
	_play_scene_playlist_track()
	return scene_music


func _play_scene_playlist_track() -> void:
	if not is_instance_valid(carried_music) or scene_playlist.is_empty():
		return
	var track := scene_playlist[playlist_index].duplicate() as AudioStreamMP3
	track.loop = false
	carried_music.stream = track
	carried_music.play()


func _advance_scene_playlist() -> void:
	if scene_playlist.is_empty():
		return
	playlist_index = (playlist_index + 1) % scene_playlist.size()
	_play_scene_playlist_track()


func release_scene_music(scene_path: String) -> void:
	if keep_music_for_scene_change:
		keep_music_for_scene_change = false
		return
	if music_origin_scene == scene_path and is_instance_valid(carried_music):
		carried_music.stop()
		carried_music.queue_free()
		carried_music = null
		music_origin_scene = ""
		scene_playlist.clear()
		playlist_index = 0


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
	var directory_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(save_directory()))
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
		"play_seconds": floori(play_seconds),
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
	play_seconds = maxf(0.0, float(data.get("play_seconds", 0)))
	return true


func delete_slot(slot: int) -> bool:
	if not is_valid_slot(slot) or not FileAccess.file_exists(slot_path(slot)):
		return false
	return DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot))) == OK


func play_time_text(data: Dictionary) -> String:
	if not data.has("play_seconds"):
		return "未记录（旧存档）"
	var seconds := maxi(0, int(data["play_seconds"]))
	var days := seconds / 86400
	var hours := (seconds % 86400) / 3600
	var minutes := (seconds % 3600) / 60
	if days > 0:
		return "%d天 %d小时 %d分钟" % [days, hours, minutes]
	if hours > 0:
		return "%d小时 %d分钟" % [hours, minutes]
	return "%d分钟" % minutes


func local_time_string() -> String:
	var current := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d" % [current.year, current.month, current.day, current.hour, current.minute]


func is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func slot_path(slot: int) -> String:
	return "%s/slot_%d.json" % [save_directory(), slot]


func save_directory() -> String:
	return RELEASE_SAVE_DIRECTORY if OS.has_feature("standalone") else SAVE_DIRECTORY
