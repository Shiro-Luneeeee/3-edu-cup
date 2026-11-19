extends Control

const MATCH_SCENE := "res://card.tscn"
const BEDROOM_SCENE := "res://bedroom.tscn"

@onready var start_button: Button = $LobbyPanel/Margin/Column/StartButton
@onready var cards_button: Button = $LobbyPanel/Margin/Column/CardsButton
@onready var rules_button: Button = $LobbyPanel/Margin/Column/RulesButton
@onready var back_button: Button = $LobbyPanel/Margin/Column/BackButton
@onready var cards_dialog: AcceptDialog = $CardsDialog
@onready var rules_dialog: AcceptDialog = $RulesDialog


func _ready() -> void:
	start_button.pressed.connect(func() -> void: get_tree().change_scene_to_file(MATCH_SCENE))
	cards_button.pressed.connect(func() -> void: cards_dialog.popup_centered(Vector2i(620, 460)))
	rules_button.pressed.connect(func() -> void: rules_dialog.popup_centered(Vector2i(620, 340)))
	back_button.pressed.connect(SceneFade.change_to.bind(BEDROOM_SCENE, -1.0))
