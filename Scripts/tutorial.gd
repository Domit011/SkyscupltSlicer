extends Control

@onready var deliv_tutor : Label = $Tutorial1
@onready var tutorial_video = $VideoStreamPlayer

func _ready() -> void:
	tutorial_video.hide()
	# Connect the mouse signals to our functions
	deliv_tutor.mouse_entered.connect(_on_tutorial_mouse_entered)
	deliv_tutor.mouse_exited.connect(_on_tutorial_1_mouse_exited)

func _on_tutorial_mouse_entered() -> void:
	print("mouse enter")
	tutorial_video.show()
	tutorial_video.play()

func _on_tutorial_1_mouse_exited() -> void:
	print("mouse exit")
	tutorial_video.hide()
	tutorial_video.stop()
