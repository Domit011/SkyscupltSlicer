extends Node2D

@export var section_height: float = 600.0

func _ready():
	$VisibilityNotifier.screen_exited.connect(_on_screen_exited)

func _on_screen_exited():
	queue_free() # Despawn when off-screen
	
