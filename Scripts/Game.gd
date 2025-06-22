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
@onready var section_manager: SectionManager = $SectionManager
@onready var input_display_tilemap: TileMap = $UI/InputDisplayTileMap  # Add your tilemap here

@export_group("Tile Graphics")
@export var tile_up : Texture2D
@export var tile_down : Texture2D
@export var tile_left : Texture2D
@export var tile_right : Texture2D
@export var c_tile_up : Texture2D
@export var c_tile_down : Texture2D
@export var c_tile_left : Texture2D
@export var c_tile_right : Texture2D

# Leaderboard data
var leaderboard: Array = []
var acceptable_input = ["ui_left","ui_right","ui_down","ui_up"]

# Input system variables
var input_array : Array[String] = []
var current_craft_request: Array[String] = []
var available_directions = ["left", "right", "up", "down"]
var sequence_length: int = 4  # Default sequence length

# Tilemap constants for arrow sprites (adjust these to match your tileset)
const ARROW_TILES = {
	"up": Vector2i(0, 0),      # Coordinates of up arrow in your tileset
	"down": Vector2i(1, 0),    # Coordinates of down arrow in your tileset
	"left": Vector2i(2, 0),    # Coordinates of left arrow in your tileset
	"right": Vector2i(3, 0),   # Coordinates of right arrow in your tileset
	"completed": Vector2i(4, 0), # Coordinates of completed/checked arrow in your tileset
	"empty": Vector2i(5, 0)    # Coordinates of empty/blank tile in your tileset
}
const TILEMAP_LAYER: int = 0        # Which layer to use for the arrows
const TILEMAP_SOURCE_ID: int = 0    # Your tileset source ID

func _ready() -> void:
	# Unpause game
	get_tree().paused = false
	# Initialize game state
	reset_game()
	# Generate first random sequence
	generate_random_sequence()
	# Setup tilemap position
	setup_tilemap_position()
	# Load leaderboard from file
	load_leaderboard()
	
	# Connect signals with null checks
	if restart_button:
		restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))
	else:
		print("Error: restart_button not found!")
	
	if obstacle:
		obstacle.connect("body_entered", Callable(self, "_on_obstacle_body_entered"))
	else:
		print("Error: obstacle not found!")
	
	# Position score label at top middle
	if score_label:
		var viewport_size = get_viewport_rect().size
		score_label.position = Vector2(viewport_size.x / 2, 20)  # 20 pixels from top
		# Center the label horizontally by adjusting pivot
		score_label.pivot_offset = Vector2(score_label.size.x / 2, 0)  # Center on x-axis

func generate_random_sequence(length: int = 4) -> void:
	"""Generate a random sequence of directional inputs"""
	current_craft_request.clear()
	sequence_length = length
	
	for i in range(sequence_length):
		var random_direction = available_directions[randi() % available_directions.size()]
		current_craft_request.append(random_direction)
	
	print("🎯 NEW CHALLENGE: Press these keys in order → ", current_craft_request)
	update_tilemap_display()

func generate_random_sequence_no_repeats(length: int = 4) -> void:
	"""Generate a random sequence without consecutive repeating directions"""
	current_craft_request.clear()
	sequence_length = length
	
	var last_direction = ""
	for i in range(sequence_length):
		var valid_directions = available_directions.duplicate()
		
		# Remove the last direction to prevent consecutive repeats
		if last_direction != "":
			valid_directions.erase(last_direction)
		
		var random_direction = valid_directions[randi() % valid_directions.size()]
		current_craft_request.append(random_direction)
		last_direction = random_direction
	
	print("🎯 NEW CHALLENGE (No Repeats): Press these keys in order → ", current_craft_request)
	update_tilemap_display()

func increase_difficulty() -> void:
	"""Increase sequence length as game progresses"""
	var new_length = min(8, 3 + int(score / 100))  # Cap at 8, increase every 100 points
	if new_length != sequence_length:
		print("🔥 DIFFICULTY INCREASED! New sequence length: ", new_length, " (Score: ", int(score), ")")
	generate_random_sequence(new_length)

func _physics_process(delta: float) -> void:
	if not is_game_over:
		# Increase score constantly
		score += delta * 10  # Adjust multiplier for score rate (10 points per second)
		update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d" % int(score)

func reset_game() -> void:
	# Unpause game
	get_tree().paused = false
	# Reset score and game state
	score = 0.0
	is_game_over = false
	update_score_display()
	# Reset player position
	if player:
		player.position = Vector2(600, -650)
	if score_label:
		score_label.visible = true
	# Hide death screen
	if death_screen:
		death_screen.visible = false
	if section_manager:
		section_manager.reset()
	
	# Generate new sequence when game resets
	generate_random_sequence()
	update_tilemap_display()

func game_over() -> void:
	get_tree().paused = true
	is_game_over = true
	# Save score to leaderboard
	save_to_leaderboard(int(score))
	
	if death_screen and final_score_label and leaderboard_label and score_label:
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
	if leaderboard_label:
		var text = "Leaderboard:\n"
		for i in range(leaderboard.size()):
			text += "%d. %d\n" % [i + 1, leaderboard[i]]
		leaderboard_label.text = text

func _on_restart_button_pressed() -> void:
	if section_manager:
		section_manager.sections.clear()
	# Unpause game
	get_tree().paused = false
	reset_game()

# Add the missing signal handler for obstacle collision
func _on_obstacle_body_entered(body: Node2D) -> void:
	if body == player:
		game_over()

func _input(event: InputEvent) -> void:
	var input_pos = input_array.size()
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode not in [KEY_UP,KEY_DOWN,KEY_RIGHT,KEY_LEFT]:
			return
		
		var input_received = ""
		if event.is_action_pressed("ui_up"):
			input_received = "up"
		elif event.is_action_pressed("ui_down"):
			input_received = "down"
		elif event.is_action_pressed("ui_left"):
			input_received = "left"
		elif event.is_action_pressed("ui_right"):
			input_received = "right"
		
		# Check if the input matches the expected input at current position
		if input_received != "" and input_pos < current_craft_request.size():
			if current_craft_request[input_pos] == input_received:
				input_array.append(input_received)
				print("✅ CORRECT! You pressed: ", input_received.to_upper(), " | Progress: ", input_array.size(), "/", current_craft_request.size())
				update_tilemap_display()  # Update visual progress
			else:
				input_array.clear()
				print("❌ WRONG KEY! Expected: ", current_craft_request[input_pos].to_upper(), " but you pressed: ", input_received.to_upper(), " | SEQUENCE RESET!")
				update_tilemap_display()  # Reset visual progress
				return
		
		# Check if sequence is complete
		if input_array.size() == current_craft_request.size():
			print("🎉 SEQUENCE COMPLETED! Great job!")
			input_array.clear()
			
			# Give bonus points for completing sequence
			score += 50  # Bonus points for completing sequence
			print("💰 BONUS: +50 points! New score: ", int(score))
			
			# Generate a new random sequence automatically
			generate_random_sequence(sequence_length)

func update_tilemap_display() -> void:
	"""Update the tilemap to show the current sequence and progress"""
	if not input_display_tilemap:
		print("⚠️ Warning: input_display_tilemap not found!")
		return
	
	# Clear the current tilemap display
	input_display_tilemap.clear_layer(TILEMAP_LAYER)
	
	# Display the current sequence
	for i in range(current_craft_request.size()):
		var direction = current_craft_request[i]
		var tile_position = Vector2i(i, 0)  # Horizontal layout, adjust as needed
		
		# Check if this input has been completed
		if i < input_array.size():
			# Show completed tile (e.g., checkmark or highlighted arrow)
			var completed_coords = ARROW_TILES["completed"]
			input_display_tilemap.set_cell(TILEMAP_LAYER, tile_position, TILEMAP_SOURCE_ID, completed_coords, 0)
		else:
			# Show the required arrow direction
			if direction in ARROW_TILES:
				var arrow_coords = ARROW_TILES[direction]
				input_display_tilemap.set_cell(TILEMAP_LAYER, tile_position, TILEMAP_SOURCE_ID, arrow_coords, 0)
			else:
				print("⚠️ Warning: Unknown direction: ", direction)

func clear_tilemap_display() -> void:
	"""Clear all tiles from the display"""
	if input_display_tilemap:
		input_display_tilemap.clear_layer(TILEMAP_LAYER)

func setup_tilemap_position() -> void:
	"""Position the tilemap in a good location on screen"""
	if input_display_tilemap:
		var viewport_size = get_viewport_rect().size
		# Position at top-left, below the score
		input_display_tilemap.position = Vector2(50, 80)  # Adjust as needed
