extends Control

func _ready() -> void:
	# Debug: Print when _ready is called
	print("Leaderboard _ready() called")
	
	# Load and display leaderboard
	load_leaderboard()
	print("Leaderboard loaded, size: ", leaderboard.size())
	print("Leaderboard data: ", leaderboard)
	
	# Setup UI positioning first
	setup_ui_positions()
	
	# Update display after UI setup
	update_leaderboard_display()
	
	# Re-setup positions after text is set for perfect centering
	setup_ui_positions()
	
	# Start menu music when entering any menu scene
	AudioManager.start_menu_music()

func _exit_tree() -> void:
	# Don't stop the music when switching between menus
	# Only stop when going to game scene
	pass

# Leaderboard file path
const LEADERBOARD_FILE: String = "user://leaderboard.json"

# UI References
@onready var leaderboard_label: Label = $LeaderboardLabel
@onready var background: ColorRect = $Background
@onready var exit_button: Button = $ExitButton

# Leaderboard data
var leaderboard: Array = []

# Signal to notify when leaderboard is closed
signal leaderboard_closed

func setup_ui_positions() -> void:
	"""Setup UI element positions"""
	var viewport_size = get_viewport_rect().size
	
	# Setup background first
	if background:
		background.color = Color(0, 0, 0, 0.8)  # Semi-transparent black background
		background.size = viewport_size
		background.position = Vector2(0, 0)
	
	# Center the leaderboard label on screen
	if leaderboard_label:
		# Set the label to fill a large area for proper centering
		leaderboard_label.size = Vector2(600, 400)  # Give it a decent size
		leaderboard_label.position = Vector2(
			(viewport_size.x - leaderboard_label.size.x) / 2,
			(viewport_size.y - leaderboard_label.size.y) / 2
		)
		# Center alignment
		leaderboard_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		leaderboard_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Position exit button in top right
	if exit_button:
		var button_size = exit_button.size
		exit_button.position = Vector2(
			viewport_size.x - button_size.x - 20,  # 20px margin from right edge
			20  # 20px margin from top edge
		)
	
	# Set this control to fill the entire viewport
	position = Vector2(0, 0)
	size = viewport_size

func load_leaderboard() -> void:
	"""Load leaderboard data from file"""
	print("Loading leaderboard from: ", LEADERBOARD_FILE)
	
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if file:
		var file_content = file.get_as_text()
		print("File content: ", file_content)
		
		var json = JSON.new()
		var error = json.parse(file_content)
		if error == OK and json.data is Array:
			leaderboard = json.data
			print("Successfully loaded leaderboard: ", leaderboard)
		else:
			print("JSON parse error: ", error)
			leaderboard = []
		file.close()
	else:
		print("No leaderboard file found, creating empty leaderboard")
		leaderboard = []

func save_to_leaderboard(new_score: int) -> void:
	"""Save a new score to the leaderboard"""
	leaderboard.append(new_score)
	leaderboard.sort()
	leaderboard.reverse()
	if leaderboard.size() > 5:
		leaderboard.resize(5)
	
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		file.close()

func update_leaderboard_display() -> void:
	"""Update the leaderboard display"""
	print("Updating leaderboard display...")
	
	if not leaderboard_label:
		print("ERROR: leaderboard_label is null!")
		return
		
	print("leaderboard_label found: ", leaderboard_label.name)
	
	var text = "🏆 LEADERBOARD 🏆\n\n"
	if leaderboard.size() > 0:
		print("Displaying ", leaderboard.size(), " scores")
		for i in range(leaderboard.size()):
			var medal = ""
			match i:
				0: medal = "🥇"
				1: medal = "🥈"
				2: medal = "🥉"
				_: medal = "  "
			text += "%s %d. %d points\n" % [medal, i + 1, leaderboard[i]]
	else:
		print("No scores to display")
		text += "No scores yet!\nPlay to set the first record!"
	
	leaderboard_label.text = text
	print("Final text set: ", text)

func show_leaderboard_with_new_score(new_score: int) -> void:
	"""Show leaderboard with a new score added"""
	save_to_leaderboard(new_score)
	update_leaderboard_display()
	visible = true

func show_leaderboard() -> void:
	"""Show the leaderboard without adding a new score"""
	load_leaderboard()
	update_leaderboard_display()
	visible = true

func hide_leaderboard() -> void:
	"""Hide the leaderboard"""
	visible = false
	leaderboard_closed.emit()

func _on_exit_button_pressed() -> void:
	"""Handle exit button press"""
	hide_leaderboard()
