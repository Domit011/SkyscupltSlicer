extends Button

var leaderboard_pressed: bool = false
@onready var leaderboard: Control = $UI/leaderboard

func _ready() -> void:
	# Hide leaderboard when the node is ready
	leaderboard.visible = false

func _on_pressed() -> void:
	# Toggle the leaderboard_pressed state
	leaderboard_pressed = true
	#show the leaderboard when the button is pressed
	leaderboard.visible = true
