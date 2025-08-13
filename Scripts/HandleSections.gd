extends Node2D
class_name SectionManager

@export var section_scenes: Array[PackedScene] # Array of section scenes
@export var spawn_offset: float = 350.0 # Distance from top section to spawn next
@export var player: Node2D # Reference to player node

var current_top_y: float = 0.0 # Y-position of the topmost section
var sections: Array[Node] = [] # Active sections
var safe_sections_spawned: int = 0 # Track how many safe sections have been spawned
var max_safe_sections: int = 3 # Number of safe sections to spawn at start

func _ready():
	reset() # Initialize the game state

func reset():
	# Clear existing sections
	for section in sections: 	
		section.queue_free()
	sections.clear()
	
	# Reset safe section counter
	safe_sections_spawned = 0
	
	# Validate setup
	if section_scenes.is_empty():
		push_error("SectionManager: No section scenes assigned in the Inspector!")
		return
	if not player:
		push_error("SectionManager: Player node not assigned in the Inspector!")
		return
	
	# Reset top y-position
	current_top_y = 0.0
	print("✅ SectionManager: Using scene at index 0 as safe starting scene for first ", max_safe_sections, " sections")
	print("🎯 Total scenes available: ", section_scenes.size())
	
	# Spawn initial safe section at y=0
	spawn_section(Vector2(0, 0))

func _physics_process(delta):
	if section_scenes.is_empty() or not player:
		return # Skip if setup is incomplete
	
	# Check if player is close to the top of the current section
	if player.position.y < current_top_y + spawn_offset:
		spawn_section(Vector2(0, current_top_y - get_section_height(section_scenes[0])))
	
	# Despawn sections too far below
	for section in sections.duplicate():
		if section.position.y > player.position.y + 300: # Adjust threshold
			sections.erase(section)
			section.queue_free()

func spawn_section(pos: Vector2):
	if section_scenes.is_empty():
		push_error("SectionManager: Cannot spawn section, no scenes available!")
		return
	
	var section_scene: PackedScene
	var section_index: int
	
	# First 3 spawns: always use the safe scene (index 0)
	if safe_sections_spawned < max_safe_sections:
		section_scene = section_scenes[0]
		section_index = 0
		safe_sections_spawned += 1
		print("🛡️ Spawning SAFE section ", safe_sections_spawned, "/", max_safe_sections, " (index 0)")
	else:
		# Subsequent spawns: randomly select from scenes 1 and above (excluding the safe scene)
		if section_scenes.size() <= 1:
			push_error("SectionManager: Need at least 2 scenes (1 safe + 1+ random)!")
			return
		
		# Select random index from 1 to size-1 (excluding index 0)
		section_index = randi() % (section_scenes.size() - 1) + 1
		section_scene = section_scenes[section_index]
		print("🎲 Spawning random scene at index: ", section_index, " (safe sections complete)")
	
	# Instantiate and position the section
	var section = section_scene.instantiate()
	section.position = pos
	add_child(section)
	sections.append(section)
	
	print("📍 Section spawned at position: ", section.global_position)
	
	# Update the topmost y-position
	current_top_y = pos.y
	
	# Connect obstacle signals to Game.gd
	var game_node = get_tree().current_scene
	for obstacle in section.get_tree().get_nodes_in_group("obstacles"):
		if obstacle is Area2D or obstacle is PhysicsBody2D:
			if obstacle.has_signal("body_entered") and not obstacle.body_entered.is_connected(Callable(game_node, "_on_obstacle_body_entered")):
				obstacle.body_entered.connect(Callable(game_node, "_on_obstacle_body_entered"))

func get_section_height(section_scene: PackedScene) -> float:
	var temp_section = section_scene.instantiate()
	var height = temp_section.section_height
	temp_section.queue_free()
	return height
