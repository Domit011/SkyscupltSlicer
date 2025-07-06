extends Node

func _ready():
	print("=== VOLUME DEBUG INFO ===")
	print("Scene: ", get_tree().current_scene.name)
	print("AudioManager exists: ", AudioManager != null)
	
	if AudioManager:
		print("Music volume setting: ", AudioManager.get_music_volume_percent(), "%")
		print("SFX volume setting: ", AudioManager.get_sfx_volume_percent(), "%")
		
		if AudioManager.menu_music_player:
			print("Music player volume_db: ", AudioManager.menu_music_player.volume_db)
			print("Music player exists: ", AudioManager.menu_music_player != null)
		else:
			print("❌ Music player is null!")
			
		if AudioManager.sfx_player:
			print("SFX player volume_db: ", AudioManager.sfx_player.volume_db)
			print("SFX player exists: ", AudioManager.sfx_player != null)
		else:
			print("❌ SFX player is null!")
	
	print("========================")

func _input(event):
	if event.is_action_pressed("ui_select"):  # Space bar
		print("🔄 Forcing volume application...")
		AudioManager.ensure_volume_applied()
