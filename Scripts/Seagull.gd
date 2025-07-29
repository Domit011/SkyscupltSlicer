extends AudioStreamPlayer2D
#
#
#@onready var audio_player = $AudioStreamPlayer2D
#@onready var visibility_notifier = $VisibleOnScreenNotifier2D
#
#func _ready():
	#if visibility_notifier == null:
		#print("Error: VisibleOnScreenNotifier2D not found!")
		#return
	#visibility_notifier.connect("screen_entered", _on_screen_entered)
#
#func _on_screen_entered():
	#if not audio_player.playing:
		#audio_player.play()
