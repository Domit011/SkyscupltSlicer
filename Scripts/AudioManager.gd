extends Node

# Audio players
var menu_music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Music resources
var menu_music_resource: AudioStream
var is_menu_music_playing: bool = false

# Volume settings (0.0 to 1.0)
var music_volume: float = 1.0
var sfx_volume: float = 1.0

func _ready() -> void:
	print("🔊 AudioManager _ready() called")
	
	# Create the audio players
	menu_music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	# Add to scene tree
	add_child(menu_music_player)
	add_child(sfx_player)
	
	# Load your menu music
	menu_music_resource = preload("res://SFX/Crystal Cavern.ogg")
	menu_music_player.stream = menu_music_resource
	menu_music_player.stream.loop = true
	
	# Load saved volume settings
	load_volume_settings()

func start_menu_music() -> void:
	if not is_menu_music_playing:
		menu_music_player.play()
		is_menu_music_playing = true
		print("🎵 Menu music started")

func stop_menu_music() -> void:
	if is_menu_music_playing:
		menu_music_player.stop()
		is_menu_music_playing = false
		print("🎵 Menu music stopped")

func is_playing_menu_music() -> bool:
	return is_menu_music_playing and menu_music_player.playing

func play_sfx(sound: AudioStream):
	if sound:
		sfx_player.stream = sound
		sfx_player.play()

# SIMPLIFIED Volume control - directly on players
func set_music_volume_percent(percent: float):
	print("🎵 Setting music volume to: ", percent, "%")
	music_volume = percent / 100.0
	
	# Apply directly to the music player
	var db = linear_to_db(music_volume)
	db = clamp(db, -80.0, 0.0)
	menu_music_player.volume_db = db
	
	print("🎵 Music player volume_db set to: ", menu_music_player.volume_db)
	save_volume_settings()

func set_sfx_volume_percent(percent: float):
	print("🔊 Setting SFX volume to: ", percent, "%")
	sfx_volume = percent / 100.0
	
	# Apply directly to the SFX player
	var db = linear_to_db(sfx_volume)
	db = clamp(db, -80.0, 0.0)
	sfx_player.volume_db = db
	
	print("🔊 SFX player volume_db set to: ", sfx_player.volume_db)
	save_volume_settings()

func get_music_volume_percent() -> float:
	return music_volume * 100.0

func get_sfx_volume_percent() -> float:
	return sfx_volume * 100.0

func save_volume_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://audio_settings.cfg")
	print("💾 Volume settings saved")

func load_volume_settings():
	var config = ConfigFile.new()
	var error = config.load("user://audio_settings.cfg")
	
	if error == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		print("📁 Volume settings loaded - Music: ", get_music_volume_percent(), "%, SFX: ", get_sfx_volume_percent(), "%")
	else:
		music_volume = 1.0
		sfx_volume = 1.0
		print("📁 No save file found, using defaults")
	
	# Apply the loaded volumes immediately
	set_music_volume_percent(get_music_volume_percent())
	set_sfx_volume_percent(get_sfx_volume_percent())
