extends CharacterBody2D

# Movement variables
@export var base_move_speed: float = 400.0 # Base left-right speed in pixels/second
@export var base_upward_speed: float = 100.0 # Base upward speed in pixels/second
@export var speed_reduction_per_item: float = 0.02 # 2% speed reduction per item
@export var tilt_angle: float = 15.0 # Tilt angle in degrees
@export var tilt_speed: float = 5.0 # How fast the player tilts (higher = faster)
@export var game_manager : Node2D

# Current effective speeds (calculated based on inventory)
var current_move_speed: float = 400.0
var current_upward_speed: float = 100.0

# Signal for item delivery
signal item_delivered

# FIX: Single delivery flag - only deliver once per zone visit
var has_delivered_in_current_zone: bool = false
var current_delivery_zone: Area2D = null

# FIX: Track ALL collision shapes that are in drop-off zones
var collision_shapes_in_dropoff: int = 0

func _ready() -> void:
	print("Player Position:  " , global_position,"   " ,position)
	# Debug prints to find the game manager
	print("🔍 Player node path: ", get_path())
	print("🔍 Player parent: ", get_parent())
	print("🔍 Player parent name: ", get_parent().name if get_parent() else "No parent")
	
	# CRITICAL: Make sure the hit box area is properly configured
	var hit_box = get_node_or_null("HitBox")  # Adjust path as needed
	if hit_box and hit_box is Area2D:
		print("✅ Found HitBox Area2D: ", hit_box.name)
		
		# Enable monitoring
		hit_box.monitoring = true
		hit_box.monitorable = true
		
		# Connect signals if not already connected
		if not hit_box.area_entered.is_connected(_on_hit_box_area_entered):
			hit_box.area_entered.connect(_on_hit_box_area_entered)
			print("✅ Connected area_entered signal")
		
		# FIX: Also connect area_exited to properly track when player leaves zones
		if not hit_box.area_exited.is_connected(_on_hit_box_area_exited):
			hit_box.area_exited.connect(_on_hit_box_area_exited)
			print("✅ Connected area_exited signal")
		
		if not hit_box.body_entered.is_connected(_on_hit_box_body_entered):
			hit_box.body_entered.connect(_on_hit_box_body_entered)
			print("✅ Connected body_entered signal")
		
		# Debug collision settings
		print("🔍 HitBox collision_layer: ", hit_box.collision_layer)
		print("🔍 HitBox collision_mask: ", hit_box.collision_mask)
		print("🔍 HitBox monitoring: ", hit_box.monitoring)
		print("🔍 HitBox monitorable: ", hit_box.monitorable)
		
		# Check for collision shapes
		for child in hit_box.get_children():
			if child is CollisionShape2D:
				print("✅ Found collision shape: ", child.name, " - Shape: ", child.shape)
	else:
		print("❌ HitBox Area2D not found! Looking for Area2D children...")
		for child in get_children():
			if child is Area2D:
				print("🔍 Found Area2D child: ", child.name)
	
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
	
	# Initialize speeds
	update_movement_speed()

func update_movement_speed() -> void:
	"""Update both horizontal and vertical speeds based on inventory size"""
	var inventory_size = 0
	
	# Try multiple ways to get inventory size
	if game_manager == null:
		# Try to find game manager if not set
		find_game_manager()
	
	# Get inventory size from game manager
	if game_manager != null:
		if game_manager.has_method("get") and game_manager.get("player_inventory") != null:
			inventory_size = game_manager.player_inventory.size()
			
		elif "player_inventory" in game_manager:
			inventory_size = game_manager.player_inventory.size()
			
		else:
			print("❌ game_manager exists but no player_inventory found")
			print("🔍 Available properties: ", game_manager.get_property_list())
	else:
		print("❌ game_manager is null in update_movement_speed")
	
	# Calculate speed reduction: 1.0 - (inventory_size * speed_reduction_per_item)
	var speed_multiplier = 1.0 - (inventory_size * speed_reduction_per_item)
	
	# Ensure speed doesn't go below a reasonable minimum (20% of base speed)
	speed_multiplier = max(speed_multiplier, 0.2)
	
	# Apply the multiplier to both base speeds
	current_upward_speed = base_upward_speed * speed_multiplier
	current_move_speed = base_move_speed * speed_multiplier
	
	# Debug output to see the speed changes
	if inventory_size > 0:
		pass

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
	
	# Get left-right input using basic A/D keys
	var direction = 0.0
	if Input.is_physical_key_pressed(KEY_A):
		direction -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		direction += 1.0
	
	velocity.x = direction * current_move_speed
	
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

# FIX: Track collision shapes entering/exiting drop-off zones
func _on_hit_box_area_exited(area: Area2D) -> void:
	print("🚪 Hit box area collision EXITED with: ", area.name)
	
	# Check if this was a drop-off zone
	for group in area.get_groups():
		if group == "DropOff":
			collision_shapes_in_dropoff -= 1
			collision_shapes_in_dropoff = max(0, collision_shapes_in_dropoff)  # Prevent negative values
			
			print("📊 Collision shapes still in drop-off: ", collision_shapes_in_dropoff)
			
			# Only reset delivery flag when ALL collision shapes have exited drop-off zones
			if collision_shapes_in_dropoff == 0:
				has_delivered_in_current_zone = false
				current_delivery_zone = null
				print("✅ Player completely exited drop-off zones - delivery flag reset")
			break

func _on_hit_box_area_entered(area: Area2D) -> void:
	print("🎯 Hit box area collision detected with: ", area.name)
	print("🎯 Area groups: ", area.get_groups())
	print("🎯 Area collision_layer: ", area.collision_layer)
	print("🎯 Area collision_mask: ", area.collision_mask)
	
	# Check ALL groups, not just DropOff
	for group in area.get_groups():
		print("🔍 Checking group: ", group)
		if group == "DropOff":
			print("📦 CONFIRMED: Collided with drop-off zone!")
			
			# FIX: Track collision shapes entering drop-off zones
			collision_shapes_in_dropoff += 1
			print("📊 Collision shapes in drop-off: ", collision_shapes_in_dropoff)
			
			# FIX: Only process delivery if we haven't already delivered in this zone visit
			if has_delivered_in_current_zone:
				print("⚠️ Already delivered in current zone visit, skipping...")
				break
			
			# FIX: Mark this zone as current delivery zone
			current_delivery_zone = area
			
			# Force find game manager every time to be sure
			var gm = null
			
			# Method 1: Try the cached reference
			if game_manager != null and game_manager.has_method("game_over"):
				gm = game_manager
				print("✅ Using cached game_manager: ", gm.name)
			
			# Method 2: Search scene tree
			if gm == null:
				var root = get_tree().current_scene
				print("🔍 Searching scene tree from root: ", root.name)
				for child in root.get_children():
					print("🔍 Checking child: ", child.name, " - Has game_over: ", child.has_method("game_over"))
					if child.has_method("game_over"):
						gm = child
						game_manager = gm  # Cache it
						print("✅ Found game_manager: ", child.name)
						break
			
			# Method 3: Try getting by group (if your game manager is in a group)
			if gm == null:
				var game_managers = get_tree().get_nodes_in_group("GameManager")
				if game_managers.size() > 0:
					gm = game_managers[0]
					game_manager = gm
					print("✅ Found game_manager by group: ", gm.name)
			
			# Now handle the delivery logic
			if gm != null:
				print("📦 Game manager confirmed: ", gm.name)
				
				# Get inventory with multiple fallback methods
				var inventory_size = 0
				var inventory_found = false
				
				# Try direct property access
				if "player_inventory" in gm:
					inventory_size = gm.player_inventory.size()
					inventory_found = true
					print("✅ Found inventory via direct access, size: ", inventory_size)
				# Try get method
				elif gm.has_method("get") and gm.get("player_inventory") != null:
					inventory_size = gm.get("player_inventory").size()
					inventory_found = true
					print("✅ Found inventory via get method, size: ", inventory_size)
				# Try custom getter
				elif gm.has_method("get_inventory_size"):
					inventory_size = gm.get_inventory_size()
					inventory_found = true
					print("✅ Found inventory via custom getter, size: ", inventory_size)
				
				if not inventory_found:
					print("❌ Could not find player_inventory!")
					print("🔍 Available properties in game manager:")
					for prop in gm.get_property_list():
						if "inventory" in prop.name.to_lower():
							print("  - ", prop.name)
					return
				
				print("📦 FINAL CHECK - Inventory size: ", inventory_size)
				
				# THE CRITICAL MOMENT: Check if player has items to deliver
				if inventory_size > 0:
					print("🚀 SUCCESS: Player has ", inventory_size, " items! Emitting delivery signal...")
					
					# FIX: Mark that we've delivered in this zone visit
					has_delivered_in_current_zone = true
					print("🔒 Set delivery flag - no more deliveries until player exits completely")
					
					item_delivered.emit()
				else:
					print("❌❌❌ NO ITEMS TO DELIVER! ❌❌❌")
					print("💀💀💀 GAME OVER - Empty inventory delivery attempt! 💀💀💀")
					
					# FIX: Still mark as delivered to prevent multiple game over calls
					has_delivered_in_current_zone = true
					
					# Multiple attempts to call game over
					if gm.has_method("game_over"):
						print("🔥🔥🔥 CALLING GAME_OVER() NOW! 🔥🔥🔥")
						gm.call("game_over")  # Use call() method for extra reliability
						print("✅ game_over() called successfully")
					else:
						print("❌ CRITICAL ERROR: game_over method not found!")
						print("🔍 Available methods in game manager:")
						for method in gm.get_method_list():
							print("  - ", method.name)
						# Force quit as emergency
						print("🔥 EMERGENCY QUIT!")
						get_tree().quit()
			else:
				print("❌❌❌ CRITICAL FAILURE: No game manager found anywhere!")
				print("🔥 EMERGENCY QUIT!")
				get_tree().quit()
			
			break  # Exit the group loop once we handle DropOff
