extends Control

const BOARD_SIZE := Vector2(1680.0, 941.0)
const BOARD_PATH := "res://images/shop_board.png"
const NOTE_PATH := "res://images/ui/note.png"
const BEDROOM_SCENE := "res://scenes/bedroom.tscn"
const CATEGORIES := ["推荐", "学习", "娱乐", "其他"]
const CATEGORY_ICONS := ["★", "▤", "♫", "···"]
const ShopProducts := preload("res://scripts/shop_products.gd")
const SocialCharacters := preload("res://scripts/social_characters.gd")

@export var clothing_only := false

var board: TextureRect
var page_layer: TextureRect
var catalogue: Control
var catalogue_scroll: ScrollContainer
var list_layer: Control
var preview_layer: Control
var balance_label: Label
var purchase_button: Button
var purchase_message: Label
var gift_picker: ColorRect
var category_buttons: Array[TextureButton] = []
var category_labels: Array[Label] = []
var category_icons: Array[Label] = []
var selected_index := 0
var selected_product_index := -1
var visible_products: Array[int] = []
var products: Array[Dictionary] = []
var product_buttons: Array[Button] = []
var product_textures: Array[Texture2D] = []
var layout_scale := 1.0
var layout_origin := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	products.assign(ShopProducts.CLOTHING_PRODUCTS if clothing_only else ShopProducts.PRODUCTS)
	if clothing_only:
		var shade := ColorRect.new()
		shade.color = Color(0.12, 0.07, 0.20, 0.67)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var board_texture := load_png_texture(BOARD_PATH)
	var note_texture := load_png_texture(NOTE_PATH) if not clothing_only else null
	board = TextureRect.new()
	board.name = "ShopBoard"
	board.texture = board_texture
	board.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	board.stretch_mode = TextureRect.STRETCH_SCALE
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(board)

	for index in range(0 if clothing_only else CATEGORIES.size()):
		var button := TextureButton.new()
		button.name = "Category%d" % index
		button.texture_normal = note_texture
		button.texture_hover = note_texture
		button.texture_pressed = note_texture
		button.ignore_texture_size = true
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_to_group("soft_selection")
		button.pressed.connect(select_category.bind(index))
		button.z_index = 2
		add_child(button)

		var label := Label.new()
		label.name = "CategoryLabel"
		label.text = CATEGORIES[index]
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 38.0
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color("594375"))
		label.add_theme_color_override("font_outline_color", Color("fff0cc"))
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_font_size_override("font_size", 23)
		button.add_child(label)
		category_labels.append(label)

		var icon := Label.new()
		icon.name = "CategoryIcon"
		icon.text = CATEGORY_ICONS[index]
		icon.position = Vector2(16.0, 0.0)
		icon.size = Vector2(44.0, 78.0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_theme_color_override("font_color", Color("775b97"))
		icon.add_theme_color_override("font_outline_color", Color("fff0cc"))
		icon.add_theme_constant_override("outline_size", 2)
		icon.add_theme_font_size_override("font_size", 25)
		button.add_child(icon)
		category_icons.append(icon)
		category_buttons.append(button)

	# The page is layered over the category notes, with the purple base beneath both.
	var atlas := AtlasTexture.new()
	atlas.atlas = board_texture
	atlas.region = Rect2(262.0, 45.0, 1396.0, 810.0)
	page_layer = TextureRect.new()
	page_layer.name = "BookPageLayer"
	page_layer.texture = atlas
	page_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	page_layer.stretch_mode = TextureRect.STRETCH_SCALE
	page_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page_layer.z_index = 3
	add_child(page_layer)
	for product in products:
		product_textures.append(load_png_texture(product["image"]))
	create_catalogue()
	PlayerState.changed.connect(update_purchase_display)

	var back_button := Button.new()
	back_button.name = "BackButton"
	back_button.text = "×"
	back_button.flat = true
	back_button.focus_mode = Control.FOCUS_NONE
	back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	back_button.z_index = 10
	back_button.add_theme_color_override("font_color", Color("65487d"))
	back_button.add_theme_color_override("font_hover_color", Color("b95c68"))
	back_button.add_theme_font_size_override("font_size", 48)
	back_button.pressed.connect(close_shop)
	add_child(back_button)

	resized.connect(update_layout)
	update_layout()
	select_category(0)


func load_png_texture(path: String) -> Texture2D:
	return load(path) as Texture2D


func update_layout() -> void:
	if board == null:
		return
	layout_scale = minf(size.x / BOARD_SIZE.x, size.y / BOARD_SIZE.y)
	layout_origin = (size - BOARD_SIZE * layout_scale) * 0.5
	board.position = layout_origin
	board.size = BOARD_SIZE * layout_scale
	for index in category_buttons.size():
		var button := category_buttons[index]
		button.position = layout_origin + Vector2(50.0, 194.0 + index * 145.0) * layout_scale
		button.size = Vector2(216.0, 78.0) * layout_scale
		category_labels[index].offset_left = 38.0 * layout_scale
		category_labels[index].add_theme_font_size_override("font_size", maxi(1, roundi(23.0 * layout_scale)))
		category_icons[index].position = Vector2(16.0, 0.0) * layout_scale
		category_icons[index].size = Vector2(44.0, 78.0) * layout_scale
		category_icons[index].add_theme_font_size_override("font_size", maxi(1, roundi(25.0 * layout_scale)))
	page_layer.position = layout_origin + Vector2(262.0, 45.0) * layout_scale
	page_layer.size = Vector2(1396.0, 810.0) * layout_scale
	if catalogue != null:
		catalogue.position = layout_origin
		catalogue.scale = Vector2.ONE * layout_scale
	var back_button := get_node_or_null("BackButton") as Button
	if back_button != null:
		back_button.position = layout_origin + Vector2(1580.0, 48.0) * layout_scale
		back_button.size = Vector2(58.0, 58.0) * layout_scale
		back_button.add_theme_font_size_override("font_size", maxi(1, roundi(48.0 * layout_scale)))


func select_category(index: int) -> void:
	selected_index = index
	for current_index in category_buttons.size():
		var button := category_buttons[current_index]
		var selected := current_index == selected_index
		button.z_index = 5 if selected else 2
		button.pivot_offset = button.size * 0.5
		var target_scale := Vector2.ONE * (1.14 if selected else 1.0)
		var target_modulate := Color(1.0, 0.88, 0.62, 1.0) if selected else Color(0.72, 0.70, 0.82, 1.0)
		var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", target_scale, 0.16)
		tween.parallel().tween_property(button, "modulate", target_modulate, 0.16)
	refresh_catalogue()


func create_catalogue() -> void:
	catalogue = Control.new()
	catalogue.name = "Catalogue"
	catalogue.size = BOARD_SIZE
	catalogue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalogue.z_index = 4
	add_child(catalogue)
	catalogue.add_child(make_catalog_label("服装店" if clothing_only else "商品简介", Vector2(328, 100), Vector2(410, 46), 31, Color("624675")))
	catalogue.add_child(make_catalog_label("在售服装" if clothing_only else "商品一览", Vector2(860, 100), Vector2(500, 46), 31, Color("624675")))
	balance_label = make_catalog_label("", Vector2(1350, 108), Vector2(220, 36), 22, Color("624675"))
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	catalogue.add_child(balance_label)
	var divider := ColorRect.new()
	divider.position = Vector2(816, 135)
	divider.size = Vector2(2, 650)
	divider.color = Color("dec6d5")
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalogue.add_child(divider)
	catalogue_scroll = ScrollContainer.new()
	catalogue_scroll.name = "ProductScroll"
	catalogue_scroll.position = Vector2(850, 147)
	catalogue_scroll.size = Vector2(720, 645)
	catalogue_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalogue.add_child(catalogue_scroll)
	list_layer = Control.new()
	list_layer.custom_minimum_size = Vector2(700, 645)
	list_layer.size = Vector2(700, 645)
	list_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalogue_scroll.add_child(list_layer)
	preview_layer = Control.new()
	preview_layer.position = Vector2(320, 148)
	preview_layer.size = Vector2(465, 640)
	preview_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	catalogue.add_child(preview_layer)


func refresh_catalogue() -> void:
	if list_layer == null:
		return
	for child in list_layer.get_children():
		list_layer.remove_child(child)
		child.queue_free()
	product_buttons.clear()
	visible_products.clear()
	for index in products.size():
		if clothing_only or selected_index == 0 or products[index]["category"] == selected_index:
			visible_products.append(index)
	list_layer.custom_minimum_size = Vector2(700, maxi(645, ceili(visible_products.size() / 2.0) * 165))
	list_layer.size = list_layer.custom_minimum_size
	catalogue_scroll.scroll_vertical = 0
	for row in visible_products.size():
		var product_index := visible_products[row]
		var product := products[product_index]
		var button := Button.new()
		button.name = "Product%d" % product_index
		button.position = Vector2((row % 2) * 355, (row / 2) * 165)
		button.size = Vector2(335, 150)
		button.clip_contents = true
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_to_group("soft_selection")
		button.pressed.connect(select_product.bind(product_index))
		list_layer.add_child(button)
		product_buttons.append(button)
		var icon := make_fitted_texture(product_textures[product_index], Rect2(13, 12, 124, 124))
		button.add_child(icon)
		var name_label := make_catalog_label(product["name"], Vector2(143, 31), Vector2(180, 90), 21, Color("604374"))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_child(name_label)
		var price_label := make_catalog_label("%d 金" % product["price"], Vector2(148, 119), Vector2(160, 28), 17, Color("946b53"))
		button.add_child(price_label)
	if not visible_products.is_empty():
		select_product(visible_products[0])


func select_product(index: int) -> void:
	if not visible_products.has(index):
		return
	selected_product_index = index
	for row in product_buttons.size():
		var button := product_buttons[row]
		var selected := visible_products[row] == index
		button.add_theme_stylebox_override("normal", make_row_style(selected))
		button.add_theme_stylebox_override("hover", make_row_style(true))
		button.add_theme_stylebox_override("pressed", make_row_style(true))
	for child in preview_layer.get_children():
		preview_layer.remove_child(child)
		child.queue_free()
	var product := products[index]
	var image := make_fitted_texture(product_textures[index], Rect2(45, 14, 370, 285))
	preview_layer.add_child(image)
	var title := make_catalog_label(product["name"], Vector2(25, 307), Vector2(420, 70), 28, Color("604374"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_layer.add_child(title)
	var description := make_catalog_label(product["description"], Vector2(28, 390), Vector2(415, 123), 19, Color("8a7188"))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_layer.add_child(description)
	var effect_description := "送礼时  好感 +%d" % product["gift_affection"] if product.has("gift_affection") else "购买时  %s" % effect_text(product["effects"])
	if product.has("round_effects"):
		effect_description += "\n每回合  %s" % effect_text(product["round_effects"])
	var effect_label := make_catalog_label(effect_description, Vector2(28, 511), Vector2(420, 58), 19, Color("674b86"))
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_layer.add_child(effect_label)
	var cost_label := make_catalog_label("花费：%d 金" % product["price"], Vector2(28, 573), Vector2(220, 36), 21, Color("946b53"))
	preview_layer.add_child(cost_label)
	purchase_message = make_catalog_label("", Vector2(28, 609), Vector2(250, 42), 16, Color("a65166"))
	purchase_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_layer.add_child(purchase_message)
	purchase_button = Button.new()
	purchase_button.text = "购买"
	purchase_button.position = Vector2(284, 582)
	purchase_button.size = Vector2(155, 50)
	purchase_button.focus_mode = Control.FOCUS_NONE
	purchase_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	purchase_button.add_to_group("purchase_button")
	purchase_button.add_theme_font_size_override("font_size", 22)
	purchase_button.pressed.connect(buy_selected_product)
	preview_layer.add_child(purchase_button)
	update_purchase_display()


func effect_text(effects: Dictionary) -> String:
	var names := {"money": "金钱", "intelligence": "智商", "emotional_intelligence": "情商", "physical_strength": "体魄", "upgrade_points": "升级点", "max_energy": "精力上限", "max_health": "心态上限", "current_energy": "精力"}
	var parts: Array[String] = []
	for key in names:
		if effects.has(key):
			parts.append("%s +%d" % [names[key], effects[key]])
	if effects.has("social_efficiency_percent"):
		parts.append("社交效率 +%d%%" % effects["social_efficiency_percent"])
	return "、".join(parts)


func update_purchase_display() -> void:
	if balance_label == null or purchase_button == null or selected_product_index < 0:
		return
	balance_label.text = "余额：%d 金" % PlayerState.money
	var product := products[selected_product_index]
	var product_id := ShopProducts.product_id(product)
	var owned: bool = not product.get("repeatable", false) and PlayerState.owned_products.has(product_id)
	var needs_recipient := product.has("gift_affection")
	var no_recipient := needs_recipient and PlayerState.affection_gift_targets().is_empty()
	var can_afford: bool = PlayerState.money >= product["price"]
	purchase_button.disabled = owned or no_recipient or not can_afford
	if owned:
		purchase_button.text = "已拥有"
	elif no_recipient:
		purchase_button.text = "无送礼对象"
	elif not can_afford:
		purchase_button.text = "金钱不足"
	else:
		purchase_button.text = "购买并送礼" if needs_recipient else "购买"


func buy_selected_product() -> void:
	if not visible_products.has(selected_product_index) or purchase_button.disabled or is_instance_valid(gift_picker):
		return
	var product := products[selected_product_index]
	if product.has("gift_affection"):
		show_gift_picker(product)
		return
	var product_id := ShopProducts.product_id(product)
	if PlayerState.try_buy_product(product_id, product["price"], product.get("repeatable", false), product["effects"]):
		UiSounds.play_purchase()
		purchase_message.text = "购买成功，回合收益从下轮开始" if product.has("round_effects") else "购买成功，效果已生效"
	else:
		purchase_message.text = "无法购买"


func show_gift_picker(product: Dictionary) -> void:
	var recipients := PlayerState.affection_gift_targets()
	if recipients.is_empty():
		update_purchase_display()
		return

	gift_picker = ColorRect.new()
	gift_picker.name = "GiftPicker"
	gift_picker.color = Color(0.12, 0.07, 0.20, 0.66)
	gift_picker.size = BOARD_SIZE
	gift_picker.z_index = 20
	gift_picker.mouse_filter = Control.MOUSE_FILTER_STOP
	catalogue.add_child(gift_picker)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gift_picker.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 480
	var style := make_row_style(true)
	style.bg_color = Color("fff0e6")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	var options := VBoxContainer.new()
	options.add_theme_constant_override("separation", 12)
	panel.add_child(options)
	var heading := make_catalog_label("选择收礼人", Vector2.ZERO, Vector2.ZERO, 28, Color("604374"))
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(heading)
	var price := make_catalog_label("选定后支付 %d 金" % product["price"], Vector2.ZERO, Vector2.ZERO, 19, Color("946b53"))
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(price)
	for character in recipients:
		var gain := mini(int(product["gift_affection"]), PlayerState.MAX_AFFECTION - PlayerState.affection_total(character))
		var option := Button.new()
		option.text = "%s   好感 +%d" % [character, gain]
		option.icon = SocialCharacters.avatar(character)
		option.add_theme_constant_override("icon_max_width", 46)
		option.add_theme_font_size_override("font_size", 23)
		option.custom_minimum_size.y = 58
		option.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		option.pressed.connect(buy_gift_for.bind(character, product))
		options.add_child(option)
	var cancel := Button.new()
	cancel.text = "取消"
	cancel.custom_minimum_size.y = 42
	cancel.pressed.connect(close_gift_picker)
	options.add_child(cancel)
	cancel.grab_focus()


func buy_gift_for(character: String, product: Dictionary) -> void:
	if not is_instance_valid(gift_picker):
		return
	close_gift_picker()
	var gain := PlayerState.try_buy_affection_gift(character, product["price"], product["gift_affection"])
	if gain > 0:
		UiSounds.play_purchase()
	purchase_message.text = "%s好感 +%d" % [character, gain] if gain > 0 else "无法购买"


func close_gift_picker() -> void:
	gift_picker.hide()
	gift_picker.queue_free()
	gift_picker = null


func make_fitted_texture(texture: Texture2D, box: Rect2) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture = texture
	var texture_size := texture.get_size()
	var fit_scale := minf(box.size.x / texture_size.x, box.size.y / texture_size.y)
	image.size = texture_size * fit_scale
	image.position = box.position + (box.size - image.size) * 0.5
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


func make_catalog_label(value: String, at: Vector2, dimensions: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.size = dimensions
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func make_row_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.91, 0.82, 0.96, 0.58) if selected else Color(1, 1, 1, 0.24)
	style.border_color = Color(0.68, 0.52, 0.73, 0.55) if selected else Color(0.79, 0.70, 0.79, 0.38)
	style.set_border_width_all(2 if selected else 1)
	style.set_corner_radius_all(11)
	return style


func close_shop() -> void:
	if is_instance_valid(gift_picker):
		close_gift_picker()
	elif clothing_only:
		SceneFade.play_action(queue_free, -1.0)
	else:
		SceneFade.change_to(BEDROOM_SCENE, -1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		get_viewport().set_input_as_handled()
		close_shop()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_shop()
