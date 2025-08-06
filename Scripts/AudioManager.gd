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

# Audio bus indices
var music_bus_index: int
var sfx_bus_index: int

func _ready() -> void:
	print("🔊 AudioManager _ready() called")
	
	# Get audio bus indices
	music_bus_index = AudioServer.get_bus_index("Music")
	sfx_bus_index = AudioServer.get_bus_index("SFX")
	
	# If buses don't exist, use Master bus
	if music_bus_index == -1:
		music_bus_index = AudioServer.get_bus_index("Master")
		print("⚠️ Music bus not found, using Master bus")
	
	if sfx_bus_index == -1:
		sfx_bus_index = AudioServer.get_bus_index("Master")
		print("⚠️ SFX bus not found, using Master bus")
	
	# Create the audio players
	menu_music_player = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	# Set their buses (will use Master if custom buses don't exist)
	if music_bus_index != AudioServer.get_bus_index("Master"):
		menu_music_player.bus = "Music"
	if sfx_bus_index != AudioServer.get_bus_index("Master"):
		sfx_player.bus = "SFX"
	
	# Add to scene tree
	add_child(menu_music_player)
	add_child(sfx_player)
	
	# Load your menu music
	menu_music_resource = preload("res://SFX/Music/Crystal Cavern.ogg")
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

# Function to find and control all audio players in the current scene
func apply_volume_to_all_players():
	var scene = get_tree().current_scene
	if scene:
		apply_volume_to_node_recursive(scene)

func apply_volume_to_node_recursive(node: Node):
	# Check if this node is an audio player
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		# Apply music volume to all audio players for now
		# You could add logic here to distinguish between music and SFX
		var db = linear_to_db(music_volume)
		db = clamp(db, -80.0, 0.0)
		node.volume_db = db
		print("🎵 Applied volume to audio player: ", node.name)
	
	# Recursively check children
	for child in node.get_children():
		apply_volume_to_node_recursive(child)

# Volume control using both buses AND direct player control
func set_music_volume_percent(percent: float):
	print("🎵 Setting music volume to: ", percent, "%")
	music_volume = percent / 100.0
	
	var db = linear_to_db(music_volume)
	db = clamp(db, -80.0, 0.0)
	
	# Method 1: Apply to audio bus (if it exists)
	if music_bus_index != -1:
		AudioServer.set_bus_volume_db(music_bus_index, db)
		print("🎵 Music bus volume_db set to: ", db)
	
	# Method 2: Apply directly to our menu music player
	menu_music_player.volume_db = db
	
	# Method 3: Apply to all audio players in current scene
	apply_volume_to_all_players()
	
	save_volume_settings()

func set_sfx_volume_percent(percent: float):
	print("🔊 Setting SFX volume to: ", percent, "%")
	sfx_volume = percent / 100.0
	
	var db = linear_to_db(sfx_volume)
	db = clamp(db, -80.0, 0.0)
	
	# Method 1: Apply to audio bus (if it exists)
	if sfx_bus_index != -1:
		AudioServer.set_bus_volume_db(sfx_bus_index, db)
		print("🔊 SFX bus volume_db set to: ", db)
	
	# Method 2: Apply directly to our SFX player
	sfx_player.volume_db = db
	
	# Note: For SFX, you might want separate logic to only affect SFX players
	# For now, this applies music volume to all players
	
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

# Call this function when entering a new scene to apply volume settings
func apply_settings_to_scene():
	print("🔄 Applying audio settings to current scene")
	apply_volume_to_all_players()
