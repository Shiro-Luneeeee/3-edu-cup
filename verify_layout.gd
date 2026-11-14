extends SceneTree

func _init() -> void:
	print("TEST_INIT")
	verify.call_deferred()

func verify() -> void:
	print("TEST_VERIFY")
	var packed_scene = load("res://card.tscn")
	print("SCENE=", packed_scene)
	if packed_scene == null:
		quit()
		return
	var game = packed_scene.instantiate()
	print("TEST_LOADED")
	root.add_child(game)
	await process_frame
	game.show_deck_choice()
	print("TEST_SHOWN")
	await process_frame
	var scroll = game.deck_choice_overlay.get_child(1)
	var grid = scroll.get_child(0)
	print("GRID size=", grid.size, " cards=", grid.get_child_count(), " first=", grid.get_child(0).size, " scroll=", scroll.size)
	game.choose_card_from_deck(game.deck[0])
	await create_timer(1.35).timeout
	var gap_count := 0
	for card_index in game.hand_holder.get_child_count():
		var card = game.hand_holder.get_child(card_index)
		if card.position.distance_to(game.get_fan_position(card_index, game.hand_holder.get_child_count())) > 1.0:
			gap_count += 1
	print("HAND count=", game.hand.size(), " nodes=", game.hand_holder.get_child_count(), " gaps=", gap_count, " turn=", game.turn)
	quit()
