@tool
extends EditorPlugin

const SoundLibrary := preload("res://audio/sfx/sound_library.gd")
const SOUND_DIRECTORY := "res://audio/sfx/custom"

var dock: VBoxContainer
var file_dialog: EditorFileDialog
var preview_player: AudioStreamPlayer
var status_label: Label
var catalog: Dictionary
var selected_key := ""


func _enter_tree() -> void:
	catalog = SoundLibrary.catalog()
	dock = VBoxContainer.new()
	dock.name = "音效库"
	dock.custom_minimum_size.x = 300
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)

	preview_player = AudioStreamPlayer.new()
	dock.add_child(preview_player)
	file_dialog = EditorFileDialog.new()
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.wav, *.mp3, *.ogg", "音频文件")
	file_dialog.file_selected.connect(_replace_file)
	dock.add_child(file_dialog)
	_build_rows()


func _exit_tree() -> void:
	remove_control_from_docks(dock)
	dock.queue_free()


func _build_rows() -> void:
	var title := Label.new()
	title.text = "项目音效"
	dock.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dock.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for key: String in catalog:
		var entry: Dictionary = catalog[key]
		var section := VBoxContainer.new()
		list.add_child(section)
		var name_label := Label.new()
		name_label.text = str(entry.get("label", key))
		section.add_child(name_label)
		var path_label := Label.new()
		path_label.text = str(entry.get("path", "")).get_file()
		path_label.tooltip_text = str(entry.get("path", ""))
		section.add_child(path_label)
		var controls := HBoxContainer.new()
		section.add_child(controls)
		var replace_button := Button.new()
		replace_button.text = "替换"
		replace_button.pressed.connect(_choose_file.bind(key, path_label))
		controls.add_child(replace_button)
		var preview_button := Button.new()
		preview_button.text = "试听"
		preview_button.pressed.connect(_preview.bind(key))
		controls.add_child(preview_button)
		var volume := HSlider.new()
		volume.min_value = -40.0
		volume.max_value = 12.0
		volume.step = 0.5
		volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		volume.value = float(entry.get("volume_db", 0.0))
		controls.add_child(volume)
		var value_label := Label.new()
		value_label.text = "%.1f dB" % volume.value
		controls.add_child(value_label)
		volume.value_changed.connect(_set_volume.bind(key, value_label))
		section.add_child(HSeparator.new())
	status_label = Label.new()
	dock.add_child(status_label)


func _choose_file(key: String, path_label: Label) -> void:
	selected_key = key
	file_dialog.set_meta("path_label", path_label)
	file_dialog.popup_centered_ratio(0.7)


func _replace_file(source_path: String) -> void:
	var extension := source_path.get_extension().to_lower()
	var directory := ProjectSettings.globalize_path(SOUND_DIRECTORY)
	var destination := directory.path_join("%s.%s" % [selected_key, extension])
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		status_label.text = "无法创建音效目录"
		return
	if source_path != destination and DirAccess.copy_absolute(source_path, destination) != OK:
		status_label.text = "复制音效失败"
		return
	var resource_path := "%s/%s.%s" % [SOUND_DIRECTORY, selected_key, extension]
	catalog[selected_key]["path"] = resource_path
	_save_catalog()
	var path_label: Label = file_dialog.get_meta("path_label")
	path_label.text = resource_path.get_file()
	path_label.tooltip_text = resource_path
	EditorInterface.get_resource_filesystem().scan()
	status_label.text = "已替换 %s，导入完成后可试听" % str(catalog[selected_key]["label"])


func _set_volume(value: float, key: String, value_label: Label) -> void:
	catalog[key]["volume_db"] = value
	value_label.text = "%.1f dB" % value
	_save_catalog()


func _preview(key: String) -> void:
	SoundLibrary.configure(preview_player, key)
	if preview_player.stream == null:
		status_label.text = "音频尚未导入，请稍后重试"
		return
	preview_player.play()
	status_label.text = "正在试听 %s" % str(catalog[key]["label"])


func _save_catalog() -> void:
	var file := FileAccess.open(SoundLibrary.CATALOG_PATH, FileAccess.WRITE)
	if file == null:
		status_label.text = "保存音效配置失败"
		return
	file.store_string(JSON.stringify(catalog, "  ") + "\n")
