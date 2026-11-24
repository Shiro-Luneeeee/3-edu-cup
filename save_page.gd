extends Control

const BEDROOM_SCENE := "res://bedroom.tscn"
const MAIN_MENU_SCENE := "res://main_menu.tscn"
const RoundCalendar := preload("res://round_calendar.gd")

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var back_button: Button = $BackButton
@onready var skip_button: Button = $SkipButton
@onready var slots: VBoxContainer = $Slots
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog
@onready var notice: AcceptDialog = $Notice

var pending_action := ""
var pending_slot := 0


func _ready() -> void:
	var saving := SaveManager.page_mode == SaveManager.PageMode.SAVE_AND_EXIT
	title_label.text = "秋日存档" if saving else "继续旅程"
	subtitle_label.text = "选择一页，留住此刻。" if saving else "从写下的那一页继续。"
	back_button.text = "返回卧室" if saving else "返回主界面"
	skip_button.visible = saving
	back_button.pressed.connect(go_back)
	skip_button.pressed.connect(func() -> void: SceneFade.change_to(MAIN_MENU_SCENE))
	confirm_dialog.confirmed.connect(apply_confirmed_action)
	for slot in range(1, SaveManager.SLOT_COUNT + 1):
		var panel := slot_panel(slot)
		var action: Button = panel.get_node("Content/Column/Actions/ActionButton")
		var delete: Button = panel.get_node("Content/Column/Actions/DeleteButton")
		action.pressed.connect(on_slot_action.bind(slot))
		delete.pressed.connect(on_delete.bind(slot))
		refresh_slot(slot)


func slot_panel(slot: int) -> PanelContainer:
	return slots.get_node("Slot%d" % slot) as PanelContainer


func refresh_slot(slot: int) -> void:
	var panel := slot_panel(slot)
	var heading: Label = panel.get_node("Content/Column/SlotTitle")
	var details: Label = panel.get_node("Content/Column/Details")
	var action: Button = panel.get_node("Content/Column/Actions/ActionButton")
	var delete: Button = panel.get_node("Content/Column/Actions/DeleteButton")
	var data := SaveManager.read_slot(slot)
	var saving := SaveManager.page_mode == SaveManager.PageMode.SAVE_AND_EXIT
	if data.is_empty():
		heading.text = "存档 %02d · 空白" % slot
		details.text = "等待写下第一段旅程"
		action.text = "存入" if saving else "无存档"
		action.disabled = not saving
		delete.hide()
	else:
		var round_number := maxi(1, int(data["player"].get("round_number", 1)))
		var player_name := str(data["player"].get("player_name", "")).strip_edges()
		if player_name.is_empty():
			player_name = PlayerState.DEFAULT_PLAYER_NAME
		heading.text = "存档 %02d · 第 %d 回合 · %d 岁" % [slot, round_number, RoundCalendar.age(round_number)]
		details.text = "玩家：%s\n游玩时长：%s\n存档时间：%s" % [player_name, SaveManager.play_time_text(data), str(data.get("saved_local", "未知"))]
		action.text = "覆盖存档" if saving else "继续游戏"
		action.disabled = false
		delete.show()


func on_slot_action(slot: int) -> void:
	if SaveManager.page_mode == SaveManager.PageMode.LOAD:
		if SaveManager.load_slot(slot):
			SceneFade.change_to(BEDROOM_SCENE)
		else:
			show_notice("这个存档无法读取。")
		return
	if SaveManager.read_slot(slot).is_empty():
		save_and_exit(slot)
	else:
		pending_action = "overwrite"
		pending_slot = slot
		confirm_dialog.dialog_text = "用当前进度覆盖存档 %02d？" % slot
		confirm_dialog.popup_centered(Vector2i(420, 160))


func on_delete(slot: int) -> void:
	pending_action = "delete"
	pending_slot = slot
	confirm_dialog.dialog_text = "确定删除存档 %02d？删除后无法恢复。" % slot
	confirm_dialog.popup_centered(Vector2i(420, 160))


func apply_confirmed_action() -> void:
	match pending_action:
		"overwrite":
			save_and_exit(pending_slot)
		"delete":
			if SaveManager.delete_slot(pending_slot):
				refresh_slot(pending_slot)
			else:
				show_notice("删除存档失败。")
	pending_action = ""
	pending_slot = 0


func save_and_exit(slot: int) -> void:
	if SaveManager.save_slot(slot):
		SceneFade.change_to(MAIN_MENU_SCENE)
	else:
		show_notice("保存失败，请检查存档目录是否可写。")


func go_back() -> void:
	var target := BEDROOM_SCENE if SaveManager.page_mode == SaveManager.PageMode.SAVE_AND_EXIT else MAIN_MENU_SCENE
	SceneFade.change_to(target)


func show_notice(message: String) -> void:
	notice.dialog_text = message
	notice.popup_centered(Vector2i(420, 160))


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		go_back()
