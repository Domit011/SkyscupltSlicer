extends Node

var menu_music_player: AudioStreamPlayer
var menu_music_resource: AudioStream  # Store the music resource
var is_menu_music_playing: bool = false

func _ready() -> void:
	# Create the audio player
	menu_music_player = AudioStreamPlayer.new()
	add_child(menu_music_player)
	
	# Load your menu music (adjust path to your .ogg file)
	menu_music_resource = preload("res://SFX/Crystal Cavern.ogg")
	menu_music_player.stream = menu_music_resource
	menu_music_player.stream.loop = true

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
