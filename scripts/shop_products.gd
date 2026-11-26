extends RefCounted

const MALE_UNIFORM_ID := "clothing:male_school_uniform"
const MALE_UNIFORM_STAT_BONUS := 10
const SUIT_ID := "clothing:suit"
const SUIT_MONEY_BONUS := 20
const SPORTSWEAR_ID := "clothing:sportswear"
const SPORTSWEAR_ENERGY_BONUS := 15

const PRODUCTS := [
	{"name": "红色头绳", "description": "一抹鲜亮的红，系住今天的好心情。", "category": 3, "image": "res://images/shop_items/shop-red-hair-ribbon.png", "price": 30, "effects": {"max_health": 2}},
	{"name": "五千年高考三千年模拟", "description": "厚厚的题目，适合慢慢啃。", "category": 1, "image": "res://images/shop_items/shop-5000-years-gaokao-3000-years-mock.png", "price": 70, "effects": {"intelligence": 12}, "round_effects": {"intelligence": 2}},
	{"name": "飞鸟集", "description": "一册轻盈的诗，留给课余片刻。", "category": 2, "image": "res://images/shop_items/shop-stray-birds-book.png", "price": 45, "effects": {"emotional_intelligence": 8}, "round_effects": {"emotional_intelligence": 2}},
	{"name": "芝士小黄油拿铁", "description": "芝士奶香与黄油香交融的拿铁。", "category": 3, "image": "res://images/shop_items/shop-cheese-butter-latte.png", "price": 18, "repeatable": true, "effects": {"current_energy": 8}},
	{"name": "糯米果味抹茶米酒", "description": "果香、抹茶与糯米米酒的奇妙组合。", "category": 3, "image": "res://images/shop_items/shop-fruity-matcha-rice-wine.png", "price": 25, "repeatable": true, "effects": {"current_energy": 6, "emotional_intelligence": 3}},
	{"name": "五万年高考三万年模拟", "description": "比上一册更厚，翻开就是新挑战。", "category": 1, "image": "res://images/shop_items/shop-50000-years-gaokao-30000-years-mock.png", "price": 120, "effects": {"intelligence": 22}, "round_effects": {"intelligence": 4}},
	{"name": "未寄出的信", "description": "@稻叶粽子的作品集，写给未来，也留给此刻。\n\n# 若要由你来讨论爱的话，你会说什么？\n\n", "category": 2, "image": "res://images/shop_items/shop-unsent-letter-book.png", "price": 55, "effects": {"emotional_intelligence": 14, "max_health": 2}},
	{"name": "Linux Debian 发行版", "description": "一套自由的操作系统，给好奇心留出折腾的空间。", "category": 1, "image": "res://images/shop_items/shop-debian-linux.png", "price": 80, "effects": {"upgrade_points": 12}, "round_effects": {"upgrade_points": 4}},
	{"name": "神经网络可解释性从入门到入土", "description": "从一层层参数里，试着看懂机器为什么这样回答。", "category": 1, "image": "res://images/shop_items/shop-neural-network-interpretability-book.png", "price": 90, "effects": {"intelligence": 14, "upgrade_points": 12}},
	{"name": "茉莉雪芽铁观音", "description": "一袋带着茉莉花香的茶，热水一冲，慢慢回甘。", "category": 3, "image": "res://images/shop_items/shop-jasmine-tea.png", "price": 22, "repeatable": true, "effects": {"current_energy": 6}},
	{"name": "多舛的生命", "description": "一本写给曲折人生的书，翻过低谷，也翻到新的页。", "category": 2, "image": "res://images/shop_items/shop-many-turns-of-life-book.png", "price": 55, "effects": {"emotional_intelligence": 12, "max_health": 3}},
	{"name": "Telecaster 电吉他", "description": "数摇的灵魂，硬摇的内核", "category": 2, "image": "res://images/shop_items/shop-telecaster-guitar.png", "price": 240, "effects": {"physical_strength": 20, "emotional_intelligence": 10}, "round_effects": {"physical_strength": 5}},
	{"name": "月之暗面", "description": "把夜色和月光收进唱片里，留给安静听歌的时刻。", "category": 2, "image": "res://images/shop_items/shop-dark-side-of-moon-album.png", "price": 85, "effects": {"emotional_intelligence": 8, "max_energy": 3}},
	{"name": "和自己年纪一样大的老单反", "description": "一台与你同龄的老单反，用胶片慢慢记录今天。", "category": 2, "image": "res://images/shop_items/shop-old-slr-camera.png", "price": 160, "effects": {"intelligence": 8, "emotional_intelligence": 8}, "round_effects": {"money": 18}},
]
const CLOTHING_PRODUCTS := [
	{
		"id": "clothing:trench_coat",
		"name": "风衣",
		"description": "一件浅杏色双排扣风衣，出门见朋友时穿着正合适。",
		"image": "res://images/shop_items/shop-trench-coat.png",
		"price": 120,
		"repeatable": false,
		"effects": {"social_efficiency_percent": 10},
	},
	{
		"id": "clothing:scarf",
		"name": "围巾",
		"description": "一条柔软的浅杏色格纹围巾。可以重复购买，送给已解锁的社交角色。",
		"image": "res://images/shop_items/shop-scarf.png",
		"price": 100,
		"repeatable": true,
		"gift_affection": 50,
	},
	{
		"id": MALE_UNIFORM_ID,
		"name": "校服（男款）",
		"description": "深蓝色西装式校服上衣，搭配白衬衫和条纹领带。购买后永久提高智商与情商获取效率。",
		"image": "res://images/shop_items/shop-male-school-uniform.png",
		"price": 200,
		"repeatable": false,
		"effects": {"mental_stat_efficiency_percent": MALE_UNIFORM_STAT_BONUS},
	},
	{
		"id": SUIT_ID,
		"name": "西装",
		"description": "炭灰色双排扣西装，搭配白衬衫和墨绿色领带。购买后永久提高金钱获取效率。",
		"image": "res://images/shop_items/shop-suit.png",
		"price": 200,
		"repeatable": false,
		"effects": {"money_efficiency_percent": SUIT_MONEY_BONUS},
	},
	{
		"id": SPORTSWEAR_ID,
		"name": "运动服",
		"description": "一件轻便的蓝色运动外套。穿着自在，活动起来也更有精神。",
		"image": "res://images/shop_items/shop-sportswear.png",
		"price": 150,
		"repeatable": false,
		"effects": {"max_energy_efficiency_percent": SPORTSWEAR_ENERGY_BONUS},
	},
]


static func product_id(product: Dictionary) -> String:
	return product.get("id", product["image"])


static func recurring_effects(owned_products: Array[String]) -> Dictionary:
	var totals := {}
	for product: Dictionary in PRODUCTS:
		if not product.has("round_effects") or not owned_products.has(product_id(product)):
			continue
		var effects: Dictionary = product["round_effects"]
		for key: String in effects:
			totals[key] = int(totals.get(key, 0)) + int(effects[key])
	return totals
