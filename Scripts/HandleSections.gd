extends Node2D

@export var section_scenes: Array[PackedScene] # Array of section scenes
@export var spawn_offset: float = 100.0 # Distance from top section to spawn next
@export var player: Node2D # Reference to player node

var current_top_y: float = 0.0 # Y-position of the topmost section
var sections: Array[Node] = [] # Active sections




func _ready():
	sections.clear()
	if section_scenes.is_empty():
		push_error("SectionManager: No section scenes assigned in the Inspector!")
		return
	if not player:
		push_error("SectionManager: Player node not assigned in the Inspector!")
		return
	# Spawn initial section at y=0
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
	# Randomly select a section scene
	var section_scene = section_scenes[randi() % section_scenes.size()]
	var section = section_scene.instantiate()
	section.position = pos
	add_child(section)
	sections.append(section)
	
	# Update the topmost y-position
	current_top_y = pos.y

	# Connect obstacle signals to Game.gd
	var game_node = get_tree().current_scene
	for obstacle in section.get_tree().get_nodes_in_group("obstacles"):
		if obstacle is Area2D or obstacle is PhysicsBody2D:
			obstacle.body_entered.connect(Callable(game_node, "_on_obstacle_body_entered"))

func get_section_height(section_scene: PackedScene) -> float:
	var temp_section = section_scene.instantiate()
	var height = temp_section.section_height
	temp_section.queue_free()
	return height
	
