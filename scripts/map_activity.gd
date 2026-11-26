extends "res://scripts/map_destination.gd"

const ACTIVITY_UI := preload("res://images/ui/park_jog_progress.tscn")
const Activity := preload("res://scripts/map_activity_data.gd")
const ACTIVITY_DURATION := 2.4

@export var activities: Array[Activity] = []


@onready var background: TextureRect = $Background

var highlights := Node2D.new()
var hover_hint := PanelContainer.new()
var hint_label := Label.new()
var activity_overlay: ColorRect
var activity_progress: ProgressBar
var activity_audio := AudioStreamPlayer.new()
var linked_overlay: Control
var companion_picker: ColorRect
var hovered_hotspot := -1
var pressed_hotspot := -1
var active_hotspot := -1
var pointer := Vector2.ZERO


func _ready() -> void:
	super._ready()
	add_child(activity_audio)
	highlights.name = "ActivityHighlights"
	highlights.z_index = 2
	add_child(highlights)
	for activity in activities:
		create_highlight(activity.hotspot_points)
	create_hover_hint()
	activity_overlay = ACTIVITY_UI.instantiate() as ColorRect
	add_child(activity_overlay)
	activity_progress = activity_overlay.get_node("%Progress")
	background.resized.connect(update_layout)
	mouse_exited.connect(clear_hover)
	PlayerState.changed.connect(update_hover)
	update_layout()


func can_open_character(character: String) -> bool:
	return active_hotspot < 0 and not is_instance_valid(linked_overlay) and not is_instance_valid(companion_picker) and super.can_open_character(character)


func create_highlight(points: PackedVector2Array) -> void:
	var highlight := Polygon2D.new()
	highlight.polygon = points
	highlight.uv = points
	highlight.texture = background.texture
	highlight.antialiased = true
	highlight.hide()
	highlights.add_child(highlight)

	var outline := Line2D.new()
	outline.points = points
	outline.closed = true
	outline.width = 3.0
	outline.joint_mode = Line2D.LINE_JOINT_ROUND
	outline.antialiased = true
	outline.default_color = Color(1.0, 0.91, 0.98, 0.70)
	highlight.add_child(outline)

func create_hover_hint() -> void:
	hover_hint.name = "ActivityHint"
	hover_hint.z_index = 4
	hover_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.092, 0.24, 0.94)
	style.border_color = Color(0.78, 0.61, 0.94, 0.82)
	style.set_corner_radius_all(10)
	style.set_border_width_all(1)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	hover_hint.add_theme_stylebox_override("panel", style)
	hint_label.add_theme_font_size_override("font_size", 21)
	hint_label.add_theme_color_override("font_color", Color("fff1fb"))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_hint.add_child(hint_label)
	hover_hint.hide()
	add_child(hover_hint)


func update_layout() -> void:
	var image_size := background.texture.get_size()
	var image_scale := minf(background.size.x / image_size.x, background.size.y / image_size.y)
	highlights.scale = Vector2.ONE * maxf(image_scale, 0.001)
	highlights.position = background.position + (background.size - image_size * image_scale) * 0.5
	var frame: Control = activity_overlay.get_node("%Frame")
	frame.custom_minimum_size.x = minf(420.0, size.x * 0.75)
	update_hover()


func hotspot_at(position_in_scene: Vector2) -> int:
	var image_point := highlights.transform.affine_inverse() * position_in_scene
	for index in activities.size():
		if Geometry2D.is_point_in_polygon(image_point, activities[index].hotspot_points):
			return index
	return -1


func _gui_input(event: InputEvent) -> void:
	if active_hotspot >= 0 or is_instance_valid(linked_overlay) or is_instance_valid(companion_picker):
		return
	if event is InputEventMouseMotion:
		pointer = event.position
		hovered_hotspot = hotspot_at(pointer)
		update_hover()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pointer = event.position
		hovered_hotspot = hotspot_at(pointer)
		if event.pressed:
			pressed_hotspot = hovered_hotspot
		else:
			var start := pressed_hotspot >= 0 and pressed_hotspot == hovered_hotspot
			pressed_hotspot = -1
			if start:
				start_activity(hovered_hotspot)
		update_hover()
		accept_event()


func clear_hover() -> void:
	hovered_hotspot = -1
	pressed_hotspot = -1
	update_hover()


func update_hover() -> void:
	var is_running := active_hotspot >= 0
	var visible_hotspot := active_hotspot if is_running else hovered_hotspot
	for index in highlights.get_child_count():
		var highlight: Polygon2D = highlights.get_child(index)
		highlight.visible = index == visible_hotspot
		highlight.self_modulate = Color(1.10, 1.07, 1.12) if is_running else Color(1.24, 1.18, 1.21)
	hover_hint.visible = hovered_hotspot >= 0 and not is_running
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hover_hint.visible else Control.CURSOR_ARROW
	if not hover_hint.visible:
		return
	var activity := activities[hovered_hotspot]
	var available_round := PlayerState.activity_available_round(activity.cooldown_id)
	hint_label.text = activity_hint_text(activity, available_round)
	if available_round > PlayerState.round_number or (activity.affection_gain > 0 and PlayerState.known_social_characters().is_empty()):
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	hover_hint.reset_size()
	var hint_size := hover_hint.get_combined_minimum_size()
	var y := pointer.y + 24.0
	if y + hint_size.y > size.y - 8.0:
		y = pointer.y - hint_size.y - 12.0
	hover_hint.position = Vector2(
		clampf(pointer.x + 18.0, 8.0, maxf(8.0, size.x - hint_size.x - 8.0)),
		maxf(8.0, y)
	)


func activity_hint_text(activity: Activity, available_round: int) -> String:
	if activity.overlay_scene != null:
		return activity.status_text
	var effects := PackedStringArray()
	if activity.physical_gain > 0:
		effects.append("体魄 +%d" % activity.physical_gain)
	if activity.max_health_gain > 0:
		effects.append("心态上限 +%d" % activity.max_health_gain)
	if activity.money_change > 0:
		effects.append("金钱 +%d" % PlayerState.preview_money_change(activity.money_change))
	if activity.energy_change < 0:
		effects.append("精力 %d" % activity.energy_change)
	if activity.money_change < 0:
		effects.append("金钱 %d" % activity.money_change)
	if activity.energy_change > 0:
		effects.append("精力 +%d" % activity.energy_change)
	if activity.affection_gain > 0:
		effects.append("好感度 +%d" % activity.affection_gain)
	var text := "    ".join(effects)
	if activity.affection_gain > 0:
		text = "%s\n%s\n每回合一次" % [activity.status_text, text]
		if PlayerState.known_social_characters().is_empty():
			text += "\n需要先认识一位社交对象"
	if available_round > PlayerState.round_number:
		text += "\n冷却中 · 第 %d 回合可再次行动" % available_round
	if PlayerState.current_energy + activity.energy_change < 0:
		text += "\n精力不足"
	if PlayerState.money + activity.money_change < 0:
		text += "\n金钱不足"
	return text


func start_activity(index: int) -> void:
	if active_hotspot >= 0 or is_instance_valid(linked_overlay) or is_instance_valid(companion_picker):
		return
	var activity := activities[index]
	if activity.overlay_scene != null:
		SceneFade.play_action(show_linked_overlay.bind(activity.overlay_scene))
		return
	if not PlayerState.can_apply_map_activity(activity):
		return
	if activity.affection_gain > 0:
		var companions := PlayerState.known_social_characters()
		if not companions.is_empty():
			show_companion_picker(index, companions)
		return
	run_activity(index)


func run_activity(index: int, companion: String = "") -> void:
	var activity := activities[index]
	if active_hotspot >= 0 or not PlayerState.can_apply_map_activity(activity):
		return
	active_hotspot = index
	activity_progress.value = 0.0
	activity_overlay.get_node("%Status").text = activity.status_text
	activity_overlay.show()
	if not activity.sound_effect_id.is_empty():
		preload("res://audio/sfx/sound_library.gd").configure(activity_audio, activity.sound_effect_id)
		activity_audio.play()
	update_hover()
	var progress_tween := create_tween()
	progress_tween.tween_property(activity_progress, "value", activity_progress.max_value, ACTIVITY_DURATION)
	await progress_tween.finished
	activity_audio.stop()
	PlayerState.try_apply_map_activity(activity, companion)
	activity_overlay.hide()
	active_hotspot = -1
	pointer = get_local_mouse_position()
	hovered_hotspot = hotspot_at(pointer) if Rect2(Vector2.ZERO, size).has_point(pointer) else -1
	update_hover()


func show_companion_picker(index: int, companions: Array[String]) -> void:
	clear_hover()
	companion_picker = ColorRect.new()
	companion_picker.name = "CompanionPicker"
	companion_picker.color = Color(0.15, 0.09, 0.22, 0.60)
	companion_picker.z_index = 12
	companion_picker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(companion_picker)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	companion_picker.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(400.0, size.x - 32.0)
	panel.add_theme_stylebox_override("panel", hover_hint.get_theme_stylebox("panel"))
	center.add_child(panel)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 10)
	panel.add_child(options)
	var title := Label.new()
	title.text = "选择一起逛街的角色"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	options.add_child(title)

	for character in companions:
		var button := Button.new()
		button.text = character
		button.icon = SocialCharacters.avatar(character)
		button.add_theme_constant_override("icon_max_width", 42)
		button.custom_minimum_size.y = 52
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(choose_companion.bind(index, character))
		options.add_child(button)

	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size.y = 38
	cancel.pressed.connect(close_companion_picker)
	options.add_child(cancel)
	cancel.grab_focus()


func choose_companion(index: int, character: String) -> void:
	if not is_instance_valid(companion_picker):
		return
	close_companion_picker()
	if character in PlayerState.known_social_characters():
		run_activity(index, character)


func close_companion_picker() -> void:
	companion_picker.hide()
	companion_picker.queue_free()
	companion_picker = null


func show_linked_overlay(scene: PackedScene) -> void:
	clear_hover()
	linked_overlay = scene.instantiate() as Control
	add_child(linked_overlay)


func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(companion_picker):
		if event.is_action_pressed("ui_cancel") and not event.is_echo():
			get_viewport().set_input_as_handled()
			close_companion_picker()
		return
	if is_instance_valid(linked_overlay):
		return
	if active_hotspot >= 0 and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		return
	super._unhandled_key_input(event)
