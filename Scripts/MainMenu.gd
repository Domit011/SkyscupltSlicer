extends Control  # or whatever your title screen extends

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer  # Adjust path as needed

func _ready() -> void:
	# Make sure the audio stream is set to loop
	if audio_player and audio_player.stream:
		audio_player.stream.loop = true  # For most audio formats
		audio_player.play()
