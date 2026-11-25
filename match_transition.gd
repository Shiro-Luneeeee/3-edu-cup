extends CanvasLayer

const MATCH_SCENE := "res://card.tscn"
const MATCH_MUSIC_NAME := "MatchTransitionMusic"
const MATCH_TRACK := preload("res://audio/music/Mateus Asato - The Breakup Song.mp3")

@onready var black: ColorRect = $Black
@onready var words: Label = $Words

var started := false


func begin(lobby_music: AudioStreamPlayer) -> void:
	if started:
		return
	started = true
	SceneFade.play_transition_sound()
	black.modulate.a = 0.0
	words.modulate.a = 0.0

	var match_music := AudioStreamPlayer.new()
	match_music.name = MATCH_MUSIC_NAME
	var music_stream := MATCH_TRACK.duplicate() as AudioStreamMP3
	music_stream.loop = true
	match_music.stream = music_stream
	match_music.volume_db = -24.0
	get_tree().root.add_child(match_music)
	match_music.play()
	create_tween().tween_property(match_music, "volume_db", -8.0, 1.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	create_tween().tween_property(lobby_music, "volume_db", -40.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var curtain := create_tween()
	curtain.tween_property(black, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await curtain.finished
	if is_instance_valid(lobby_music):
		lobby_music.stop()

	var writing := create_tween()
	writing.tween_property(words, "modulate:a", 1.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	writing.tween_interval(2.4)
	writing.tween_property(words, "modulate:a", 0.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await writing.finished

	var result := get_tree().change_scene_to_file(MATCH_SCENE)
	if result != OK:
		push_error("Could not open match scene: %s" % error_string(result))
		match_music.stop()
		match_music.queue_free()
		queue_free()
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var reveal := create_tween()
	reveal.tween_property(black, "modulate:a", 0.0, 1.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await reveal.finished
	queue_free()
