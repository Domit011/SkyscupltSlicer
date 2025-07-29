extends Node2D

# Score variables
var tile_vis = true
var has_item = false
var score: float = 0.0
var is_game_over: bool = false

# Node references (assign these in the editor or code)
@onready var player: CharacterBody2D = $Player
@onready var obstacle: Area2D = $Obstacle
@onready var score_label: Label = $UI/ScoreLabel
@onready var death_screen: Control = $UI/DeathScreen
@onready var final_score_label: Label = $UI/DeathScreen/FinalScoreLabel
@onready var restart_button: Button = $UI/DeathScreen/RestartButton
@onready var section_manager: Node = $SectionManager  # Relaxed type to avoid errors
@onready var input_display_tilemap: TileMap = $UI/InputDisplayTileMap
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var loselabel: Label = $UI/DeathScreen/loselabel
# Inventory UI
@onready var inventory_label: Label = $UI/InventoryLabel

@export_group("Tile Graphics")
@export var tile_up: Texture2D
@export var tile_down: Texture2D
@export var tile_left: Texture2D
@export var tile_right: Texture2D
@export var c_tile_up: Texture2D
@export var c_tile_down: Texture2D
@export var c_tile_left: Texture2D
@export var c_tile_right: Texture2D

@onready var input_1: TextureRect = %Input1
@onready var input_2: TextureRect = %Input2
@onready var input_3: TextureRect = %Input3
@onready var input_4: TextureRect = %Input4

# Input system variables
var input_array: Array[String] = []
var current_craft_request: Array[String] = []
var available_directions = ["left", "right", "up", "down"]
var sequence_length: int = 4

# Inventory system
var player_inventory: Array[String] = []
var max_inventory_size: int = 3

# Crafting state
var is_crafting_active: bool = true

func _ready() -> void:
	if audio_player and audio_player.stream:
		audio_player.stream.loop = true
		audio_player.play()
	else:
		print("❌ ERROR: AudioPlayer or stream not found!")

	# Stop menu music when entering game
	if AudioManager:
		AudioManager.stop_menu_music()
	else:
		print("❌ ERROR: AudioManager not found!")

	# Unpause game
	get_tree().paused = false
	
	# Ensure death screen and restart button process input even when paused
	if death_screen:
		death_screen.process_mode = Node.PROCESS_MODE_ALWAYS
		print("✅ DeathScreen process_mode set to PROCESS_MODE_ALWAYS")
	else:
		print("❌ ERROR: DeathScreen not found!")
	
	if restart_button:
		restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
		# Disconnect any existing connections to avoid duplicates
		if restart_button.is_connected("pressed", Callable(self, "_on_restart_button_pressed")):
			restart_button.disconnect("pressed", Callable(self, "_on_restart_button_pressed"))
		restart_button.connect("pressed", Callable(self, "_on_restart_button_pressed"))
		print("✅ Restart button signal connected successfully")
	else:
		print("❌ ERROR: restart_button not found! Please check node path: $UI/DeathScreen/RestartButton in the scene tree")
	
	if obstacle:
		if obstacle.has_signal("body_entered"):
			obstacle.connect("body_entered", Callable(self, "_on_obstacle_body_entered"))
			print("✅ Obstacle collision signal connected successfully")
		else:
			print("❌ ERROR: Obstacle doesn't have body_entered signal!")
	else:
		print("❌ ERROR: obstacle not found!")
	
	# Position UI elements
	setup_ui_positions()
	
	# Connect player delivery signal
	if player and player.has_signal("item_delivered"):
		player.connect("item_delivered", Callable(self, "_on_item_delivered"))
		print("✅ Player delivery signal connected successfully")
	else:
		print("❌ WARNING: Player node not found or doesn't have item_delivered signal!")
	
	# Initialize game state
	reset_game()
	
	# Generate first random sequence
	generate_random_sequence()
	call_deferred("update_pattern_list")

func setup_ui_positions() -> void:
	"""Setup UI element positions"""
	var viewport_size = get_viewport_rect().size
	
	# Position score label at top middle
	if score_label:
		score_label.position = Vector2(viewport_size.x / 2, 20)
		score_label.pivot_offset = Vector2(score_label.size.x / 2, 0)
	
	# Position inventory label
	if inventory_label:
		inventory_label.position = Vector2(viewport_size.x / 2, 60)
		inventory_label.pivot_offset = Vector2(inventory_label.size.x / 2, 0)

func generate_random_sequence(length: int = 4) -> void:
	"""Generate a random sequence of directional inputs"""
	current_craft_request.clear()
	sequence_length = length
	
	for i in range(sequence_length):
		var random_direction = available_directions[randi() % available_directions.size()]
		current_craft_request.append(random_direction)
	
	print("🎯 NEW CHALLENGE: Press these keys in order → ", current_craft_request)
	update_pattern_list()

func _physics_process(delta: float) -> void:
	if not is_game_over:
		# Increase score constantly
		score += delta * 10
		update_score_display()

func update_score_display() -> void:
	if score_label:
		score_label.text = "Score: %d" % int(score)
	else:
		print("❌ ERROR: score_label not found in update_score_display!")

func update_inventory_display() -> void:
	"""Update the inventory display UI"""
	if inventory_label:
		var inventory_text = "Inventory (%d/%d): " % [player_inventory.size(), max_inventory_size] 
		if player_inventory.size() == 0:
			inventory_text += "Empty"
		else:
			inventory_text += "%d items" % player_inventory.size()
		inventory_label.text = inventory_text
	else:
		print("❌ ERROR: inventory_label not found in update_inventory_display!")

func add_item_to_inventory(item_name: String) -> bool:
	"""Add an item to player inventory. Returns true if successful."""
	if player_inventory.size() < max_inventory_size:
		player_inventory.append(item_name)
		print("📦 Item added to inventory: ", item_name)
		update_inventory_display()
		return true
	else:
		print("❌ Inventory full! Cannot add item: ", item_name)
		return false

func _on_item_delivered() -> void:
	"""Called when player enters a drop-off zone"""
	print("🔔 _on_item_delivered() function called!")
	print("📦 Current inventory size: ", player_inventory.size())
	print("📦 Current inventory contents: ", player_inventory)
	if player_inventory.size() > 0:
		# Check if inventory was full before delivery
		var was_inventory_full = (player_inventory.size() == max_inventory_size)
		
		# Remove the first item from inventory
		var delivered_item = player_inventory[0]
		player_inventory.remove_at(0)
		print("📤 Item delivered: ", delivered_item)
		print("📦 Inventory after delivery: ", player_inventory)
		update_inventory_display()
		
		# Update player speed after inventory change
		if player and player.has_method("update_movement_speed"):
			player.update_movement_speed()
		
		# Give points for delivery
		score += 100
		print("💰 DELIVERY BONUS: +100 points! New score: ", int(score))
		
		# RE-ENABLE CRAFTING if it was disabled due to full inventory
		if was_inventory_full and not is_crafting_active:
			print("🔓 Re-enabling crafting after delivery!")
			is_crafting_active = true
			# Clear any existing input and generate new sequence
			input_array.clear()
			generate_random_sequence(sequence_length)
		
		# If crafting was already active but no sequence exists, generate one
		elif is_crafting_active and current_craft_request.is_empty():
			print("🎯 Generating new sequence after delivery!")
			input_array.clear()
			generate_random_sequence(sequence_length)
			
func update_pattern_list() -> void:
	"""Update the visual pattern display"""
	# Define texture mappings for complete and incomplete states
	var texture_mappings = {
		"complete": {
			"up": c_tile_up,
			"down": c_tile_down,
			"left": c_tile_left,
			"right": c_tile_right
		},  
		"incomplete": {
			"up": tile_up,
			"down": tile_down,
			"left": tile_left,
			"right": tile_right
		}
	}
	
	# Store input references in an array for easier iteration
	var input_nodes = [input_1, input_2, input_3, input_4]
	
	# Check if we have all required nodes and textures
	for node in input_nodes:
		if not node:
			print("⚠️ Warning: Missing input node in pattern display")
			return
	
	# Initially set all inputs to incomplete textures based on current sequence
	for i in range(min(input_nodes.size(), current_craft_request.size())):
		var direction = current_craft_request[i]
		if direction in texture_mappings["incomplete"]:
			input_nodes[i].texture = texture_mappings["incomplete"][direction]
	
	# Update completed inputs based on input_array
	for i in range(min(input_array.size(), input_nodes.size())):
		if i < current_craft_request.size():
			var direction = current_craft_request[i]
			if direction in texture_mappings["complete"]:
				input_nodes[i].texture = texture_mappings["complete"][direction]

func reset_game() -> void:
	print("🔄 Resetting game state...")
	# Unpause game
	get_tree().paused = false
	
	# Reset score and game state
	score = 0.0
	is_game_over = false
	is_crafting_active = true
	tile_vis = true  # Show tiles when game is active
	player_inventory.clear()
	input_array.clear()
	current_craft_request.clear()  # Ensure craft request is cleared
	update_score_display()
	update_inventory_display()
	
	# Show tile graphics when game starts
	set_tile_graphics_visibility(true)
	
	# Reset player position
	if player:
		player.position = Vector2(600, -650)
	else:
		print("❌ ERROR: Player node not found during reset!")
	
	if score_label:
		score_label.visible = true
	else:
		print("❌ ERROR: Score label not found during reset!")
		
	# Hide death screen
	if death_screen:
		death_screen.visible = false
	else:
		print("❌ ERROR: Death screen not found during reset!")
		
	# Reset section manager
	if section_manager:
		if section_manager.has_method("reset"):
			section_manager.reset()
			print("✅ Section manager reset successfully")
		elif section_manager.get("sections") != null and section_manager.get("sections") is Array:
			section_manager.sections.clear()
			print("✅ Section manager sections cleared directly")
		else:
			print("❌ ERROR: SectionManager does not have reset method or sections property!")
	else:
		print("❌ ERROR: section_manager not found during reset!")
	
	# Generate new sequence when game resets
	generate_random_sequence()
	print("✅ Game reset complete")
	
# Add this new function to control tile visibility
func set_tile_graphics_visibility(visible: bool) -> void:
	"""Control the visibility of all tile graphics"""
	var input_nodes = [input_1, input_2, input_3, input_4]
	for node in input_nodes:
		if node:
			node.visible = visible
	print("🎨 Tile graphics visibility set to: ", visible)


func game_over() -> void:
	if is_game_over:
		return  # Prevent multiple game over calls
		
	print("🎮 GAME OVER - Final Score: ", int(score))
	get_tree().paused = true
	is_game_over = true
	tile_vis = false  # Changed to false since we're hiding tiles
	is_crafting_active = false
	
	# Hide tile graphics when game is over
	set_tile_graphics_visibility(false)
	
	# Save the score to leaderboard file
	save_score_to_leaderboard(int(score))
	
	if death_screen and final_score_label and score_label:
		# Show death screen with final score
		final_score_label.text = "Final Score: %d" % int(score)
		death_screen.visible = true
		score_label.visible = false
	else:
		print("❌ ERROR: Missing UI elements for game over screen!")

func save_score_to_leaderboard(new_score: int) -> void:
	"""Save score to leaderboard file"""
	const LEADERBOARD_FILE: String = "user://leaderboard.json"
	var leaderboard: Array = []
	
	# Load existing leaderboard
	var file = FileAccess.open(LEADERBOARD_FILE, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data is Array:
			leaderboard = json.data
		file.close()
	
	# Add new score and sort
	leaderboard.append(new_score)
	leaderboard.sort()
	leaderboard.reverse()
	if leaderboard.size() > 5:
		leaderboard.resize(5)
	
	# Save updated leaderboard
	file = FileAccess.open(LEADERBOARD_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(leaderboard))
		file.close()
	
	print("💾 Score saved to leaderboard: ", new_score)

func _on_restart_button_pressed() -> void:
	print("🔄 Restart button pressed!")
	reset_game()

func _on_obstacle_body_entered(body: Node2D) -> void:
	if body == player and not is_game_over:
		print("💥 Player hit obstacle - Game Over!")
		game_over()

func _input(event: InputEvent) -> void:
	# Only process input if crafting is active and game isn't over
	if not is_crafting_active or is_game_over:
		return
		
	var input_pos = input_array.size()
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.physical_keycode not in [KEY_UP, KEY_DOWN, KEY_RIGHT, KEY_LEFT]:
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
				print("✅ Correct input: ", input_received, " (", input_array.size(), "/", current_craft_request.size(), ")")
				update_pattern_list()
			else:
				print("❌ Wrong input! Expected: ", current_craft_request[input_pos], ", Got: ", input_received)
				input_array.clear()
				update_pattern_list()
				return
		
		# Check if sequence is complete
		if input_array.size() == current_craft_request.size():
			print("🎉 SEQUENCE COMPLETED! Crafting item...")
			complete_crafting_sequence()

func complete_crafting_sequence() -> void:
	"""Handle the completion of a crafting sequence"""
	is_crafting_active = false
	
	# Create item name from sequence
	var item_name = "Item_" + "_".join(current_craft_request)
	
	# Try to add item to inventory
	if add_item_to_inventory(item_name):
		# Give bonus points for completing sequence
		score += 50
		print("💰 CRAFTING BONUS: +50 points! New score: ", int(score))
		
		# Show completed sequence first
		update_pattern_list()
		
		# Only generate new sequence if inventory isn't full
		if player_inventory.size() < max_inventory_size:
			print("work")
			# Wait a moment, then generate new sequence
			await get_tree().create_timer(1.0).timeout
			# Clear input array BEFORE generating new sequence
			input_array.clear()
			is_crafting_active = true
			generate_random_sequence(sequence_length)
		else:
			print("🎒 Inventory full! Deliver items to continue crafting.")
			# Keep the completed sequence displayed when inventory is full
			# Don't clear input_array here so the completed tiles remain visible
	else:
		print("❌ Cannot craft - inventory full!")
		input_array.clear()
		is_crafting_active = true
