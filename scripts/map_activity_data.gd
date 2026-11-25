extends Resource

@export var hotspot_points := PackedVector2Array()
@export var status_text := ""
@export var sound_effect_id := ""
@export var overlay_scene: PackedScene
@export_range(-100, 100) var energy_change := -5
@export_range(-100, 100) var money_change := 0
@export_range(0, 100) var physical_gain := 0
@export_range(0, 100) var max_health_gain := 0
@export_range(0, 100) var affection_gain := 0
@export var cooldown_id := ""
@export_range(0, 100) var cooldown_rounds := 0
