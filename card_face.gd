extends TextureRect

const CardCatalog := preload("res://card_catalog.gd")
const SOURCE_SIZE := Vector2(1060, 1484)
const DIGIT_COLOR := Color("b7322a")
const DIGIT_FONT_SIZE := 72
const COST_REGION := Rect2i(106, 127, 119, 120)
const YUE_COST_REGION := Rect2i(89, 40, 99, 119)
const YUE_OATH_COST_REGION := Rect2i(127, 44, 80, 114)
const FUSHIMI_COST_REGION := Rect2i(83, 63, 94, 113)
const FUSHIMI_NIGHT_WALK_COST_REGION := Rect2i(75, 53, 90, 118)
const FUSHIMI_LAST_COST_REGION := Rect2i(74, 53, 94, 113)
const SIGNED_FIELDS := ["health_change", "health_per_hand", "next_energy_change", "starting_energy_gain"]

const DIGIT_FONT := preload("res://fonts/StoryFont.tres")
static var paper_patches: Dictionary[Vector3i, Texture2D] = {}

var base_id := 0
var numbers: Dictionary = {}
var original_numbers: Dictionary = {}
var cost_override := -1
var edits: Control


func set_card(card_id: int, preview_numbers: Dictionary = {}, battle_cost: int = -1) -> void:
	base_id = PlayerState.card_base_id(card_id)
	texture = CardCatalog.texture(base_id)
	original_numbers = CardCatalog.numbers(base_id)
	numbers = PlayerState.card_numbers(card_id) if preview_numbers.is_empty() else preview_numbers
	cost_override = battle_cost
	if (numbers != original_numbers or cost_override >= 0) and edits == null:
		edits = Control.new()
		edits.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edits.draw.connect(draw_edits)
		edits.resized.connect(edits.queue_redraw)
		add_child(edits)
		edits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if edits != null:
		edits.queue_redraw()


func draw_edits() -> void:
	if numbers == original_numbers and cost_override < 0:
		return
	var art_size := size
	var is_fushimi := base_id >= CardCatalog.FUSHIMI_PEN_CARD
	var source_size := texture.get_size() if is_fushimi else SOURCE_SIZE
	if stretch_mode == STRETCH_KEEP_ASPECT_CENTERED:
		art_size = source_size * minf(size.x / source_size.x, size.y / source_size.y)
	var origin := (size - art_size) * 0.5
	var art_scale := art_size / source_size
	if cost_override >= 0:
		var is_yue := base_id >= CardCatalog.YUE_FIRST_CARD
		var cost_region := YUE_COST_REGION if is_yue else COST_REGION
		if base_id == CardCatalog.YUE_OATH_CARD:
			cost_region = YUE_OATH_COST_REGION
		elif base_id == CardCatalog.FUSHIMI_NIGHT_WALK_CARD:
			cost_region = FUSHIMI_NIGHT_WALK_COST_REGION
		elif is_fushimi:
			cost_region = FUSHIMI_LAST_COST_REGION if base_id == CardCatalog.FUSHIMI_LAST_BATTLE_CARD else FUSHIMI_COST_REGION
		var ink := Color("fff9ed") if is_yue else Color("203659")
		edits.draw_set_transform(origin, 0.0, art_scale)
		edits.draw_texture(get_paper_patch(cost_region), Vector2(cost_region.position))
		draw_digits(str(cost_override), Rect2(cost_region), origin, art_scale, ink, 113 if is_fushimi else 131)
	var regions := CardCatalog.number_regions(base_id)
	for field: String in regions:
		var value := int(numbers[field])
		if value == original_numbers[field]:
			continue
		var region: Rect2i = regions[field]
		edits.draw_set_transform(origin, 0.0, art_scale)
		edits.draw_texture(get_paper_patch(region), Vector2(region.position))
		var digits := "+%d" % value if field in SIGNED_FIELDS and value > 0 else str(value)
		var ink := Color("365989") if field == "health_per_hand" else DIGIT_COLOR
		if is_fushimi:
			ink = Color("564291")
			if field == "cost_reduction":
				digits = str(-value)
				ink = Color("24172b")
			elif field == "progress_per_discard":
				digits = "+%d" % value
		draw_digits(digits, Rect2(region), origin, art_scale, ink, DIGIT_FONT_SIZE)


func get_paper_patch(region: Rect2i) -> Texture2D:
	var key := Vector3i(base_id, region.position.x, region.position.y)
	if paper_patches.has(key):
		return paper_patches[key]
	var source := texture.get_image()
	if source.is_compressed():
		source.decompress()
	var patch := Image.create_empty(region.size.x, region.size.y, false, Image.FORMAT_RGBA8)
	# Blend the paper beside the numeral so the surrounding printed text stays intact.
	for y in region.size.y:
		var source_y := region.position.y + y
		var left := source.get_pixel(region.position.x - 1, source_y)
		var right := source.get_pixel(region.end.x, source_y)
		var vertical_edge := mini(y, region.size.y - 1 - y)
		for x in region.size.x:
			var paper := left.lerp(right, (x + 1.0) / (region.size.x + 1.0))
			var horizontal_edge := mini(x, region.size.x - 1 - x)
			paper.a = minf(1.0, mini(horizontal_edge, vertical_edge) / 4.0)
			patch.set_pixel(x, y, paper)
	paper_patches[key] = ImageTexture.create_from_image(patch)
	return paper_patches[key]


func draw_digits(digits: String, bounds: Rect2, origin: Vector2, art_scale: Vector2, ink: Color, font_size: int) -> void:
	var glyph_font := DIGIT_FONT
	var width := glyph_font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var fit := minf(1.0, (bounds.size.x - 6.0) / maxf(1.0, width))
	var baseline := (glyph_font.get_ascent(font_size) - glyph_font.get_descent(font_size)) * 0.5
	edits.draw_set_transform(origin + bounds.get_center() * art_scale, 0.0, art_scale * Vector2(fit, 1.0))
	edits.draw_string(glyph_font, Vector2(-width * 0.5, baseline), digits, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, ink)
