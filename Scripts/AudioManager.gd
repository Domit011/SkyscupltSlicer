extends Node

# Audio bus names (match your AudioBusLayout)
const MASTER_BUS = "Master"
const MUSIC_BUS = "Music"
const SFX_BUS = "SFX"

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
	# Create the audio players
	menu_music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	# Set audio buses
	menu_music_player.bus = MUSIC_BUS
	sfx_player.bus = SFX_BUS
	
	# Add to scene tree
	add_child(menu_music_player)
	add_child(sfx_player)
	
	# Load your menu music (adjust path to your .ogg file)
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

# Volume control functions
func set_music_volume_percent(percent: float):
	music_volume = percent / 100.0
	apply_music_volume()
	save_volume_settings()

func set_sfx_volume_percent(percent: float):
	sfx_volume = percent / 100.0
	apply_sfx_volume()
	save_volume_settings()

func get_music_volume_percent() -> float:
	return music_volume * 100.0

func get_sfx_volume_percent() -> float:
	return sfx_volume * 100.0

func apply_music_volume():
	var bus_index = AudioServer.get_bus_index(MUSIC_BUS)
	if bus_index != -1:
		# Convert linear volume to decibels
		var db = linear_to_db(music_volume)
		# Clamp to prevent extremely low values
		db = clamp(db, -80.0, 0.0)
		AudioServer.set_bus_volume_db(bus_index, db)

func apply_sfx_volume():
	var bus_index = AudioServer.get_bus_index(SFX_BUS)
	if bus_index != -1:
		# Convert linear volume to decibels
		var db = linear_to_db(sfx_volume)
		# Clamp to prevent extremely low values
		db = clamp(db, -80.0, 0.0)
		AudioServer.set_bus_volume_db(bus_index, db)

func save_volume_settings():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.save("user://audio_settings.cfg")

func load_volume_settings():
	var config = ConfigFile.new()
	var error = config.load("user://audio_settings.cfg")
	
	if error == OK:
		music_volume = config.get_value("audio", "music_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	else:
		# Default values if no save file exists
		music_volume = 1.0
		sfx_volume = 1.0
	
	# Apply the loaded volumes
	apply_music_volume()
	apply_sfx_volume()
