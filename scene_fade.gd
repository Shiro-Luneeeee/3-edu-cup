extends CanvasLayer

const PAPER_SWEEP := preload("res://scene_paper_sweep.gdshader")
const COVER_TIME := 0.42
const REVEAL_TIME := 0.48

var curtain := ColorRect.new()
var paper_material := ShaderMaterial.new()

func _ready() -> void:
	layer = 100
	paper_material.shader = PAPER_SWEEP
	curtain.material = paper_material
	curtain.mouse_filter = Control.MOUSE_FILTER_STOP
	curtain.hide()
	add_child(curtain)
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func change_to(scene_path: String, direction: float = 1.0) -> void:
	if curtain.visible:
		return
	paper_material.set_shader_parameter("direction", direction)
	set_sweep_progress(0.0)
	curtain.show()
	await move_paper(0.0, 0.5, COVER_TIME, Tween.EASE_OUT)

	var tree := get_tree()
	var result := tree.change_scene_to_file(scene_path)
	if result == OK:
		await tree.scene_changed
	else:
		push_error("Could not open %s: %s" % [scene_path, error_string(result)])

	await move_paper(0.5, 1.0, REVEAL_TIME, Tween.EASE_IN_OUT)
	curtain.hide()

func play_action(action: Callable, direction: float = 1.0) -> void:
	if curtain.visible:
		return
	paper_material.set_shader_parameter("direction", direction)
	set_sweep_progress(0.0)
	curtain.show()
	await move_paper(0.0, 0.5, COVER_TIME, Tween.EASE_OUT)
	action.call()
	await get_tree().process_frame
	await move_paper(0.5, 1.0, REVEAL_TIME, Tween.EASE_IN_OUT)
	curtain.hide()

func move_paper(from: float, to: float, duration: float, easing: Tween.EaseType) -> void:
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(easing)
	tween.tween_method(set_sweep_progress, from, to, duration)
	await tween.finished

func set_sweep_progress(value: float) -> void:
	paper_material.set_shader_parameter("progress", value)

func _input(_event: InputEvent) -> void:
	if curtain.visible:
		get_viewport().set_input_as_handled()
