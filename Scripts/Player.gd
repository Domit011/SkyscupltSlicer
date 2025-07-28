extends CharacterBody2D

# Movement variables
@export var move_speed: float = 400.0 # Left-right speed in pixels/second
@export var base_upward_speed: float = 100.0 # Base upward speed in pixels/second
@export var speed_reduction_per_item: float = 0.05 # 5% speed reduction per item
@export var tilt_angle: float = 15.0 # Tilt angle in degrees
@export var tilt_speed: float = 5.0 # How fast the player tilts (higher = faster)
@export var game_manager : Node2D

# Current effective upward speed (calculated based on inventory)
var current_upward_speed: float = 100.0

# Signal for item delivery
signal item_delivered

func _ready() -> void:
	print("Player Position:  " , global_position,"   " ,position)
	# Debug prints to find the game manager
	print("🔍 Player node path: ", get_path())
	print("🔍 Player parent: ", get_parent())
	print("🔍 Player parent name: ", get_parent().name if get_parent() else "No parent")
	
	# Try different ways to find game manager
	var parent = get_parent()
	if parent:
		print("🔍 Parent children: ")
		for child in parent.get_children():
			print("  - ", child.name, " (", child.get_script(), ")")
	
	# Try to find game manager by script
	var root = get_tree().current_scene
	print("🔍 Current scene: ", root.name)
	for child in root.get_children():
		print("🔍 Scene child: ", child.name, " - Script: ", child.get_script())
		if child.get_script() and child.has_method("game_over"):
			print("✅ Found node with game_over method: ", child.name)
			game_manager = child
			break
	
	# Initialize speed
	update_movement_speed()

func update_movement_speed() -> void:
	"""Update the current upward speed based on inventory size"""
	var inventory_size = 0
	
	# Try multiple ways to get inventory size
	if game_manager == null:
		# Try to find game manager if not set
		find_game_manager()
	
	# Get inventory size from game manager
	if game_manager != null:
		if game_manager.has_method("get") and game_manager.get("player_inventory") != null:
			inventory_size = game_manager.player_inventory.size()
			print("📦 Found inventory via get(): ", inventory_size, " items")
		elif "player_inventory" in game_manager:
			inventory_size = game_manager.player_inventory.size()
			print("📦 Found inventory via direct access: ", inventory_size, " items")
		else:
			print("❌ game_manager exists but no player_inventory found")
			print("🔍 Available properties: ", game_manager.get_property_list())
	else:
		print("❌ game_manager is null in update_movement_speed")
	
	# Calculate speed reduction: 1.0 - (inventory_size * speed_reduction_per_item)
	var speed_multiplier = 1.0 - (inventory_size * speed_reduction_per_item)
	
	# Ensure speed doesn't go below a reasonable minimum (20% of base speed)
	speed_multiplier = max(speed_multiplier, 0.2)
	
	# Apply the multiplier to base speed
	current_upward_speed = base_upward_speed * speed_multiplier
	
	print("🏃 Speed updated - Inventory: %d items, Speed: %.1f (%.0f%% of base)" % [
		inventory_size, 
		current_upward_speed, 
		speed_multiplier * 100
	])

func find_game_manager() -> void:
	"""Helper function to find the game manager"""
	# Try parent
	if get_parent() and get_parent().has_method("game_over"):
		game_manager = get_parent()
		print("✅ Found game_manager in parent for speed system")
		return
	
	# Try scene root
	if get_tree().current_scene and get_tree().current_scene.has_method("game_over"):
		game_manager = get_tree().current_scene
		print("✅ Found game_manager in scene root for speed system")
		return
	
	# Search scene children
	var root = get_tree().current_scene
	for child in root.get_children():
		if child.has_method("game_over"):
			game_manager = child
			print("✅ Found game_manager in scene children for speed system: ", child.name)
			return

func _physics_process(delta: float) -> void:
	# Update speed based on current inventory (but only every few frames for performance)
	# Check every 10 frames instead of every frame
	if Engine.get_process_frames() % 10 == 0:
		update_movement_speed()
	
	# Initialize velocity
	var velocity = Vector2.ZERO
	
	# Get left-right input
	var direction = Input.get_axis("Left", "Right")
	velocity.x = direction * move_speed
	
	# Apply current upward movement (adjusted for inventory)
	velocity.y = -current_upward_speed # Negative because Godot's Y-axis is down
	
	# Handle tilting based on movement direction
	var target_rotation = 0.0
	if direction < 0: # Moving left
		target_rotation = deg_to_rad(-tilt_angle)
	elif direction > 0: # Moving right
		target_rotation = deg_to_rad(tilt_angle)
	# If direction == 0, target_rotation stays 0 (upright)
	
	# Smoothly interpolate to the target rotation
	rotation = lerp_angle(rotation, target_rotation, tilt_speed * delta)
	
	# Set the velocity and move
	self.velocity = velocity
	move_and_slide()

func _on_hit_box_body_entered(body: Node2D) -> void:
	print("🎯 Hit box collision detected with: ", body.name)
	print("🎯 Body groups: ", body.get_groups())
	
	if body.is_in_group("Obstacle"):
		print("you die")
		
		# Debug the game_manager reference
		print("🔍 game_manager value: ", game_manager)
		print("🔍 game_manager type: ", typeof(game_manager))
		
		# Try to find game_manager if it's null
		if game_manager == null:
			print("❌ game_manager is null! Trying to find it...")
			# Try parent
			if get_parent() and get_parent().has_method("game_over"):
				game_manager = get_parent()
				print("✅ Found game_manager in parent")
			# Try scene root
			elif get_tree().current_scene and get_tree().current_scene.has_method("game_over"):
				game_manager = get_tree().current_scene
				print("✅ Found game_manager in scene root")
			# Search scene children
			else:
				for child in get_tree().current_scene.get_children():
					if child.has_method("game_over"):
						game_manager = child
						print("✅ Found game_manager: ", child.name)
						break
		
		if game_manager and game_manager.has_method("game_over"):
			game_manager.game_over()
		else:
			print("❌ Still couldn't find game_manager!")

func _on_hit_box_area_entered(area: Area2D) -> void:
	print("🎯 Hit box area collision detected with: ", area.name)
	print("🎯 Area groups: ", area.get_groups())
	
	if area.is_in_group("DropOff"):
		print("📦 Collided with drop-off zone!")
		
		# Try multiple ways to find game manager
		var gm = null
		
		# Method 1: Use the exported variable
		if game_manager != null:
			gm = game_manager
			print("✅ Using exported game_manager")
		
		# Method 2: Try parent
		elif get_parent() and get_parent().has_method("game_over"):
			gm = get_parent()
			print("✅ Using parent as game_manager")
		
		# Method 3: Try scene root
		elif get_tree().current_scene and get_tree().current_scene.has_method("game_over"):
			gm = get_tree().current_scene
			print("✅ Using scene root as game_manager")
		
		# Method 4: Search all children of scene root
		else:
			var root = get_tree().current_scene
			for child in root.get_children():
				if child.has_method("game_over"):
					gm = child
					print("✅ Found game_manager in scene children: ", child.name)
					break
		
		if gm:
			print("📦 Game manager found! Inventory size: ", gm.player_inventory.size())
			# Check if player has items to deliver
			if gm.player_inventory.size() > 0:
				print("🚀 Emitting item_delivered signal...")
				item_delivered.emit()
			else:
				print("❌ No items to deliver!")
				print("💀 Game Over - No items to deliver!")
				gm.game_over()
		else:
			print("❌ CRITICAL ERROR: Could not find game manager anywhere!")
			print("❌ Available nodes in scene:")
			for child in get_tree().current_scene.get_children():
				print("  - ", child.name, " (methods: ", child.get_method_list().size(), ")")
