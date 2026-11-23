extends CanvasLayer

const Rewards := preload("res://match_rewards.gd")
const REWARD_SCENE := preload("res://match_rewards.tscn")
const EMOTIONAL_INTELLIGENCE_MONEY_REWARD := 25
const DRAFT_SCENE := "res://deck_draft.tscn"
const STAT_OFFERS := [
	[Rewards.Reward.REMOVE, Rewards.Reward.ADD, Rewards.Reward.COPY],
	[Rewards.Reward.MONEY, Rewards.Reward.AFFECTION, Rewards.Reward.UPGRADE_POINTS],
	[Rewards.Reward.MAX_ENERGY, Rewards.Reward.MAX_HEALTH, Rewards.Reward.ENERGY_SUPPLY],
]
const REWARD_SCENES := [
	"res://bedroom.tscn", "res://shop.tscn", "res://game_selection.tscn", DRAFT_SCENE,
]

var panel: Rewards
var after_rewards: Callable
var draft_return_scene := ""
var deferred_intelligence_level := 0


func _ready() -> void:
	layer = 90
	PlayerState.changed.connect(queue_check)
	get_tree().scene_changed.connect(on_scene_changed)
	SceneFade.curtain.visibility_changed.connect(queue_check)
	queue_check()


func queue_check() -> void:
	show_next_reward.call_deferred()


func on_scene_changed() -> void:
	if get_tree().current_scene.scene_file_path == "res://main_menu.tscn":
		deferred_intelligence_level = 0
	queue_check()


func continue_after_rewards(action: Callable) -> void:
	after_rewards = action
	show_next_reward()


func show_next_reward() -> void:
	if is_instance_valid(panel) or SceneFade.curtain.visible:
		return
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path not in REWARD_SCENES:
		return
	var needs_deck := not PlayerState.has_starter_deck()
	var intelligence_level := PlayerState.stat_progress(PlayerState.Stat.INTELLIGENCE).x
	var skip_intelligence := needs_deck and (
		scene.scene_file_path == DRAFT_SCENE or intelligence_level <= deferred_intelligence_level
	)
	var stat := PlayerState.next_stat_reward(skip_intelligence)
	if stat < 0:
		if after_rewards.is_valid():
			var action := after_rewards
			after_rewards = Callable()
			action.call()
		return

	panel = REWARD_SCENE.instantiate() as Rewards
	panel.level_reward_stat = stat
	panel.heading_text = "%s升至 %d 级" % [PlayerState.STAT_NAMES[stat], PlayerState.claimed_stat_levels[stat] + 1]
	panel.continue_text = "继续"
	panel.fixed_offer.assign(STAT_OFFERS[stat])
	panel.reward_skipped.connect(close_reward)
	if stat == PlayerState.Stat.INTELLIGENCE and needs_deck:
		panel.requires_starter_deck = true
		panel.heading_text = "智商升至 %d 级" % intelligence_level
		panel.continue_text = "开始组牌"
		panel.continue_requested.connect(start_reward_draft.bind(scene.scene_file_path))
		panel.deferred_requested.connect(defer_intelligence_reward)
	else:
		panel.continue_requested.connect(close_reward)
	if stat == PlayerState.Stat.EMOTIONAL_INTELLIGENCE:
		panel.money_reward = EMOTIONAL_INTELLIGENCE_MONEY_REWARD
	add_child(panel)


func start_reward_draft(return_scene: String) -> void:
	if not is_instance_valid(panel) or not panel.requires_starter_deck:
		return
	draft_return_scene = return_scene
	dismiss_panel()
	SceneFade.change_to(DRAFT_SCENE)


func take_draft_destination(default_scene: String) -> String:
	if draft_return_scene.is_empty():
		return default_scene
	var destination := draft_return_scene
	draft_return_scene = ""
	if not PlayerState.has_starter_deck():
		deferred_intelligence_level = PlayerState.stat_progress(PlayerState.Stat.INTELLIGENCE).x
	return destination


func defer_intelligence_reward() -> void:
	if not is_instance_valid(panel) or not panel.requires_starter_deck:
		return
	deferred_intelligence_level = PlayerState.stat_progress(PlayerState.Stat.INTELLIGENCE).x
	dismiss_panel()
	queue_check()


func close_reward() -> void:
	if not is_instance_valid(panel) or not panel.reward_claimed:
		return
	dismiss_panel()
	queue_check()


func dismiss_panel() -> void:
	panel.hide()
	panel.queue_free()
	panel = null


func _shortcut_input(_event: InputEvent) -> void:
	if is_instance_valid(panel):
		get_viewport().set_input_as_handled()
