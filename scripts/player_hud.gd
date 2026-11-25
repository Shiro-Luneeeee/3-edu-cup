extends Control

const IMAGE_SIZE := Vector2(1672, 941)
const POINT_BOARD_TEXTURE: Texture2D = preload("res://images/ui/point_board.png")
const HERO_PORTRAIT_TEXTURE: Texture2D = preload("res://images/character/ShiroLune_cutout.png")
const POINT_BOARD_SIZE := Vector2(580.0, 290.0)
# Slot bounds in point_board.png, from top to bottom.
const STAT_TRACK_RECTS := [
	Vector4(869.0, 257.0, 562.0, 44.0),
	Vector4(870.0, 424.0, 561.0, 44.0),
	Vector4(871.0, 592.0, 561.0, 46.0),
]
const STAT_VALUE_FONT_SIZE := 20.0
const ENERGY_BAR_WIDTH := 430.0
const ENERGY_TRACK_IN_TEXTURE := Rect2(372.0, 328.0, 1552.0, 134.0)
const ENERGY_VALUE_FONT_SIZE_IN_TEXTURE := 116.0
const ENERGY_BAR_TEXTURE := preload("res://images/ui/energy_bar.png")
const ENERGY_FILL_SHADER := preload("res://shaders/energy_bar_fill.gdshader")

var point_board: TextureRect
var point_board_material: ShaderMaterial
var stat_labels: Array[Label] = []
var stat_level_labels: Array[Label] = []
var energy_bar: TextureRect
var energy_material: ShaderMaterial
var energy_label: Label

func _ready() -> void:
	create_point_board()
	create_energy_bar()
	PlayerState.changed.connect(update_player_display)
	resized.connect(update_layout)
	update_layout()

func update_player_display() -> void:
	update_energy_display()
	update_point_board_values()

func create_energy_bar() -> void:
	energy_bar = TextureRect.new()
	energy_bar.name = "EnergyBar"
	energy_bar.texture = ENERGY_BAR_TEXTURE
	energy_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_bar.stretch_mode = TextureRect.STRETCH_SCALE
	energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	energy_material = ShaderMaterial.new()
	energy_material.shader = ENERGY_FILL_SHADER
	var track := ENERGY_TRACK_IN_TEXTURE
	energy_material.set_shader_parameter("track_rect", Vector4(track.position.x, track.position.y, track.size.x, track.size.y))
	energy_bar.material = energy_material
	add_child(energy_bar)

	energy_label = Label.new()
	energy_label.name = "EnergyValue"
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var value_font := FontVariation.new()
	value_font.base_font = preload("res://fonts/StoryFont.tres")
	value_font.variation_embolden = 0.6
	energy_label.add_theme_font_override("font", value_font)
	energy_label.add_theme_color_override("font_color", Color.WHITE)
	energy_label.add_theme_color_override("font_outline_color", Color("47345e"))
	energy_label.add_theme_constant_override("outline_size", 3)
	energy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar.add_child(energy_label)

func update_energy_display() -> void:
	if energy_label == null:
		return
	var texture_scale := energy_bar.size.x / energy_bar.texture.get_width()
	var track := Rect2(ENERGY_TRACK_IN_TEXTURE.position * texture_scale, ENERGY_TRACK_IN_TEXTURE.size * texture_scale)
	var ratio := clampf(float(PlayerState.current_energy) / PlayerState.max_energy, 0.0, 1.0)
	energy_material.set_shader_parameter("fill_ratio", ratio)
	energy_label.text = PlayerState.energy_text()
	energy_label.add_theme_font_size_override("font_size", maxi(1, roundi(ENERGY_VALUE_FONT_SIZE_IN_TEXTURE * texture_scale)))
	energy_label.size = track.size
	energy_label.position = track.get_center() - energy_label.size * 0.5

func create_point_board() -> void:
	point_board = TextureRect.new()
	point_board.name = "PointBoard"
	point_board.texture = POINT_BOARD_TEXTURE
	point_board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	point_board.stretch_mode = TextureRect.STRETCH_SCALE
	point_board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_board_material = ShaderMaterial.new()
	point_board_material.shader = ENERGY_FILL_SHADER
	point_board_material.set_shader_parameter("track_rect", STAT_TRACK_RECTS[0])
	point_board_material.set_shader_parameter("extra_track_rects", PackedVector4Array([STAT_TRACK_RECTS[1], STAT_TRACK_RECTS[2]]))
	point_board.material = point_board_material
	add_child(point_board)

	var portrait_clip := Control.new()
	portrait_clip.name = "HeroPortraitClip"
	portrait_clip.position = Vector2(34.0, 82.0)
	portrait_clip.size = Vector2(108.0, 108.0)
	portrait_clip.clip_contents = true
	portrait_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_board.add_child(portrait_clip)
	var portrait := TextureRect.new()
	portrait.name = "HeroPortrait"
	portrait.texture = HERO_PORTRAIT_TEXTURE
	portrait.position = Vector2(-3.0, -2.0)
	portrait.size = Vector2(114.0, 114.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_clip.add_child(portrait)

	for index in STAT_TRACK_RECTS.size():
		var value_label := create_stat_label("StatValue%d" % index)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_labels.append(value_label)
		stat_level_labels.append(create_stat_label("StatLevel%d" % index))

func create_stat_label(node_name: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("594375"))
	label.add_theme_color_override("font_outline_color", Color("fff0cc"))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	point_board.add_child(label)
	return label

func update_point_board_values() -> void:
	var fill_ratios := Vector3.ZERO
	for index in stat_labels.size():
		var progress := PlayerState.stat_progress(index)
		var required := PlayerState.stat_experience_required(progress.x)
		stat_labels[index].text = "%d/%d" % [progress.y, required]
		stat_level_labels[index].text = "%d级" % progress.x
		fill_ratios[index] = float(progress.y) / required
	point_board_material.set_shader_parameter("fill_ratio", fill_ratios.x)
	point_board_material.set_shader_parameter("extra_fill_ratios", Vector2(fill_ratios.y, fill_ratios.z))

func update_layout() -> void:
	var image_scale := minf(size.x / IMAGE_SIZE.x, size.y / IMAGE_SIZE.y)
	var image_origin := (size - IMAGE_SIZE * image_scale) / 2.0
	if energy_bar != null:
		energy_bar.size = energy_bar.texture.get_size() * (ENERGY_BAR_WIDTH * image_scale / energy_bar.texture.get_width())
		energy_bar.position = Vector2((size.x - energy_bar.size.x) * 0.5, image_origin.y + 6.0 * image_scale)
	if point_board != null:
		point_board.position = image_origin + Vector2(12.0, 8.0) * image_scale
		point_board.size = POINT_BOARD_SIZE * image_scale
		var texture_scale_x := point_board.size.x / point_board.texture.get_width()
		var texture_scale_y := point_board.size.y / point_board.texture.get_height()
		var stat_font_size := maxi(1, roundi(STAT_VALUE_FONT_SIZE * image_scale))
		for index in stat_labels.size():
			var value_label := stat_labels[index]
			var level_label := stat_level_labels[index]
			var track: Vector4 = STAT_TRACK_RECTS[index]
			var center_y := (track.y + track.w * 0.5) * texture_scale_y
			value_label.add_theme_font_size_override("font_size", stat_font_size)
			value_label.size = Vector2(track.z * texture_scale_x, 34.0 * image_scale)
			value_label.position = Vector2(track.x * texture_scale_x, center_y - value_label.size.y * 0.5)
			level_label.add_theme_font_size_override("font_size", stat_font_size)
			level_label.size = Vector2(54.0, 34.0) * image_scale
			level_label.position = value_label.position + Vector2(value_label.size.x + 8.0 * image_scale, 0.0)
	update_player_display()
