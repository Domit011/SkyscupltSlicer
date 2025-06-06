extends Node2D

# Score variables
var score: float = 0.0
var is_game_over: bool = false

# Leaderboard file path
const LEADERBOARD_FILE: String = "user://leaderboard.json"

# Node references (assign these in the editor or code)
@onready var player: CharacterBody2D = $Player
@onready var obstacle: Area2D = $Obstacle
@onready var score_label: Label = $UI/ScoreLabel
@onready var death_screen: Control = $UI/DeathScreen
@onready var final_score_label: Label = $UI/DeathScreen/FinalScoreLabel
@onready var leaderboard_label: Label = $UI/DeathScreen/LeaderboardLabel
@onready var restart_button: Button = $UI/DeathScreen/RestartButton
@onready var section_manager: Node2D = $SectionManager

# Leaderboard data
var leaderboard: Array = []

func _ready() -> void:
	#unpause game
	get_tree().paused = false
	# Initialize game state
	reset_game()
	# Load leaderboard from file
	load_leaderboard()
	# Connect restart button signal
	restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	# Connect obstacle collision signal
	obstacle.connect("body_entered", Callable(self, "_on_obstacle_body_entered"))
	
	# Position score label at top middle
	var viewport_size = get_viewport_rect().size
	score_label.position = Vector2(viewport_size.x / 2, 20)  # 20 pixels from top
	# Center the label horizontally by adjusting pivot
	score_label.pivot_offset = Vector2(score_label.size.x / 2, 0)  # Center on x-axis

func _physics_process(delta: float) -> void:
	if not is_game_over:
		# Increase score constantly
		score += delta * 10  # Adjust multiplier for score rate (10 points per second)
		update_score_display()
		
	

func update_score_display() -> void:
	score_label.text = "Score: %d" % int(score)

func reset_game() -> void:
		#unpause game
	get_tree().paused = false
	# Reset score and game state
	score = 0.0
	is_game_over = false
	update_score_display()
	# Reset player position
	player.position = Vector2(600,-650)
	score_label.visible = true
	# Hide death screen
	death_screen.visible = false



func game_over() -> void:
	get_tree().paused = true
	is_game_over = true
	# Save score to leaderboard
	save_to_leaderboard(int(score))
		# Position deathscreen at top middle
	var viewport_size = get_viewport_rect().size
	death_screen.position = Vector2(viewport_size.x / 2, 20)  # 20 pixels from top
	# Center the label horizontally by adjusting pivot
	death_screen.pivot_offset = Vector2(death_screen.size.x / 2, 0)  # Center on x-axis
	# Show death screen
	final_score_label.text = "Final Score: %d" % int(score)
	update_leaderboard_display()
	death_screen.visible = true
	score_label.visible = false
	final_score_label.visible = false

func load_leaderboard() -> void:
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data is Array:
			leaderboard = json.data
		file.close()
	else:
		leaderboard = []

func save_to_leaderboard(new_score: int) -> void:
	leaderboard.append(new_score)
	leaderboard.sort()
	leaderboard.reverse()  # Highest scores first
	if leaderboard.size() > 5:  # Keep top 5 scores
		leaderboard.resize(5)
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		file.close()

func update_leaderboard_display() -> void:
	var text = "Leaderboard:\n"
	for i in range(leaderboard.size()):
		text += "%d. %d\n" % [i + 1, leaderboard[i]]
	leaderboard_label.text = text

func _on_restart_button_pressed() -> void:
	section_manager.sections.clear()#unpause game
	get_tree().paused = false
	reset_game()
