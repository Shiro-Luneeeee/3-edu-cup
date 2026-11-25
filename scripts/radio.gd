extends ColorRect

const MUSIC_DIRECTORY := "res://audio/music/"
const SUPPORTED_EXTENSIONS := ["mp3", "wav"]

@onready var music: AudioStreamPlayer = $Music
@onready var now_playing: Label = $Panel/Padding/Content/NowPlaying
@onready var status: Label = $Panel/Padding/Content/Status
@onready var track_count: Label = $Panel/Padding/Content/TrackCount
@onready var tracks: ItemList = $Panel/Padding/Content/Tracks
@onready var close_button: Button = $Panel/Padding/Content/Header/CloseButton
@onready var previous_button: Button = $Panel/Padding/Content/Controls/PreviousButton
@onready var play_pause_button: Button = $Panel/Padding/Content/Controls/PlayPauseButton
@onready var next_button: Button = $Panel/Padding/Content/Controls/NextButton
@onready var seek_slider: HSlider = $Panel/Padding/Content/Progress/SeekSlider
@onready var elapsed_label: Label = $Panel/Padding/Content/Progress/Elapsed
@onready var duration_label: Label = $Panel/Padding/Content/Progress/Duration
@onready var volume_slider: HSlider = $Panel/Padding/Content/Volume/VolumeSlider
@onready var volume_value: Label = $Panel/Padding/Content/Volume/VolumeValue

var track_paths: Array[String] = []
var current_index := -1
var seeking := false


func _ready() -> void:
	close_button.pressed.connect(close)
	previous_button.pressed.connect(play_previous)
	play_pause_button.pressed.connect(toggle_pause)
	next_button.pressed.connect(play_next)
	tracks.item_selected.connect(play_track)
	music.finished.connect(play_next)
	seek_slider.drag_started.connect(func() -> void: seeking = true)
	seek_slider.drag_ended.connect(finish_seek)
	volume_slider.value_changed.connect(set_volume)
	set_volume(volume_slider.value)
	load_tracks()
	if not track_paths.is_empty():
		play_track(0)
	else:
		now_playing.text = "这里暂时没有歌曲"
		status.text = "将 MP3 或 WAV 放入 audio/music 后重新打开电台"
		previous_button.disabled = true
		play_pause_button.disabled = true
		next_button.disabled = true


func load_tracks() -> void:
	track_paths.clear()
	for file in ResourceLoader.list_directory(MUSIC_DIRECTORY):
		if file.get_extension().to_lower() in SUPPORTED_EXTENSIONS:
			track_paths.append(MUSIC_DIRECTORY.path_join(file))
	track_paths.sort()
	tracks.clear()
	for path in track_paths:
		tracks.add_item(display_name(path))
	track_count.text = "曲目列表  ·  %d 首" % track_paths.size()


func display_name(path: String) -> String:
	return path.get_file().get_basename().replace("_", " ")


func play_track(index: int) -> void:
	if index < 0 or index >= track_paths.size():
		return
	var stream := load(track_paths[index]) as AudioStream
	if stream == null:
		status.text = "这首歌暂时无法播放"
		return
	var playback := stream.duplicate() as AudioStream
	if playback is AudioStreamMP3:
		playback.loop = false
	elif playback is AudioStreamWAV:
		playback.loop_mode = AudioStreamWAV.LOOP_DISABLED
	music.stop()
	music.stream_paused = false
	music.stream = playback
	current_index = index
	tracks.select(index)
	seek_slider.max_value = maxf(1.0, playback.get_length())
	seek_slider.set_value_no_signal(0.0)
	duration_label.text = format_time(playback.get_length())
	elapsed_label.text = "0:00"
	now_playing.text = display_name(track_paths[index])
	status.text = "正在播放  ·  %d / %d" % [index + 1, track_paths.size()]
	play_pause_button.text = "暂停"
	music.play()


func play_previous() -> void:
	if not track_paths.is_empty():
		play_track(posmod(current_index - 1, track_paths.size()))


func play_next() -> void:
	if not track_paths.is_empty():
		play_track((current_index + 1) % track_paths.size())


func toggle_pause() -> void:
	if current_index < 0:
		if not track_paths.is_empty():
			play_track(0)
		return
	music.stream_paused = not music.stream_paused
	play_pause_button.text = "继续播放" if music.stream_paused else "暂停"
	status.text = "已暂停" if music.stream_paused else "正在播放  ·  %d / %d" % [current_index + 1, track_paths.size()]


func finish_seek(_value_changed: bool) -> void:
	seeking = false
	if current_index >= 0:
		music.seek(seek_slider.value)


func set_volume(value: float) -> void:
	music.volume_db = -80.0 if value <= 0.0 else -6.0 + linear_to_db(value / 100.0)
	volume_value.text = "%d%%" % roundi(value)


func _process(_delta: float) -> void:
	if current_index < 0 or seeking:
		return
	var seconds := minf(music.get_playback_position(), seek_slider.max_value)
	seek_slider.set_value_no_signal(seconds)
	elapsed_label.text = format_time(seconds)


func format_time(seconds: float) -> String:
	var total := maxi(0, floori(seconds))
	return "%d:%02d" % [floori(total / 60.0), total % 60]


func close() -> void:
	queue_free()


func _exit_tree() -> void:
	music.stop()


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
	elif event.keycode == KEY_SPACE:
		get_viewport().set_input_as_handled()
		toggle_pause()
