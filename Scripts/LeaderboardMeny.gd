extends Control

func _ready() -> void:
	# Start menu music when entering any menu scene
	AudioManager.start_menu_music()

func _exit_tree() -> void:
	# Don't stop the music when switching between menus
	# Only stop when going to game scene
	pass
