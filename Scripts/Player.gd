extends CharacterBody2D

# Movement variables
@export var move_speed: float = 400.0 # Left-right speed in pixels/second
@export var upward_speed: float = 100.0 # Upward speed in pixels/second
@export var game_manager : Node2D

# Signal for item delivery
signal item_delivered
func _ready() -> void:
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

func _physics_process(delta: float) -> void:
	# Initialize velocity
	var velocity = Vector2.ZERO
	
	# Get left-right input
	var direction = Input.get_axis("Left", "Right")
	velocity.x = direction * move_speed
	
	# Apply constant upward movement
	velocity.y = -upward_speed # Negative because Godot's Y-axis is down
	
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
