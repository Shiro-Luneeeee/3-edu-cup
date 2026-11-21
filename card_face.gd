extends TextureRect

const CardCatalog := preload("res://card_catalog.gd")
const SOURCE_SIZE := Vector2(1060, 1484)
const DIGIT_COLOR := Color("b7322a")
const DIGIT_FONT_SIZE := 72

static var digit_font := make_digit_font()
static var paper_patches: Dictionary[Vector3i, Texture2D] = {}

var base_id := 0
var numbers: Dictionary = {}
var original_numbers: Dictionary = {}
var edits: Control


func set_card(card_id: int, preview_numbers: Dictionary = {}) -> void:
	base_id = PlayerState.card_base_id(card_id)
	texture = CardCatalog.texture(base_id)
	original_numbers = CardCatalog.numbers(base_id)
	numbers = PlayerState.card_numbers(card_id) if preview_numbers.is_empty() else preview_numbers
	if numbers != original_numbers and edits == null:
		edits = Control.new()
		edits.mouse_filter = Control.MOUSE_FILTER_IGNORE
		edits.draw.connect(draw_edits)
		edits.resized.connect(edits.queue_redraw)
		add_child(edits)
		edits.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if edits != null:
		edits.queue_redraw()


func draw_edits() -> void:
	if numbers == original_numbers:
		return
	var art_size := size
	if stretch_mode == STRETCH_KEEP_ASPECT_CENTERED:
		art_size = SOURCE_SIZE * minf(size.x / SOURCE_SIZE.x, size.y / SOURCE_SIZE.y)
	var origin := (size - art_size) * 0.5
	var art_scale := art_size / SOURCE_SIZE
	var regions := CardCatalog.number_regions(base_id)
	for field: String in regions:
		var value := int(numbers[field])
		if value == original_numbers[field]:
			continue
		var region: Rect2i = regions[field]
		edits.draw_set_transform(origin, 0.0, art_scale)
		edits.draw_texture(get_paper_patch(region), Vector2(region.position))
		var digits := "+%d" % value if field == "health_change" and value > 0 else str(value)
		draw_digits(digits, Rect2(region), origin, art_scale)


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


func draw_digits(digits: String, bounds: Rect2, origin: Vector2, art_scale: Vector2) -> void:
	var width := digit_font.get_string_size(digits, HORIZONTAL_ALIGNMENT_LEFT, -1, DIGIT_FONT_SIZE).x
	var fit := minf(1.0, (bounds.size.x - 6.0) / maxf(1.0, width))
	var baseline := (digit_font.get_ascent(DIGIT_FONT_SIZE) - digit_font.get_descent(DIGIT_FONT_SIZE)) * 0.5
	edits.draw_set_transform(origin + bounds.get_center() * art_scale, 0.0, art_scale * Vector2(fit, 1.0))
	edits.draw_string(digit_font, Vector2(-width * 0.5, baseline), digits, HORIZONTAL_ALIGNMENT_LEFT, -1.0, DIGIT_FONT_SIZE, DIGIT_COLOR)


static func make_digit_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Times New Roman", "Liberation Serif", "Noto Serif", "DejaVu Serif"])
	font.font_weight = 700
	return font
