class_name GameEntry
extends Resource

@export var id: String
@export var title: String
@export_multiline var description: String
@export_multiline var short_description: String
@export var energy_cost: int
@export var effect_description: String
@export var price: int
@export var reward_stat: String
@export var reward_amount := 10
@export_multiline var play_story: String
@export var cover: Texture2D
