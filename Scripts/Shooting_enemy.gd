# ShootingEnemy.gd
extends CharacterBody2D

@export var projectile_scene: PackedScene  # Drag your projectile scene here
@export var shoot_interval: float = 2.0   # Time between shots
@export var detection_range: float = 200.0 # How far the enemy can detect player
@export var projectile_speed: float = 150.0

var player: Node2D
var shoot_timer: Timer
var can_shoot: bool = true

func _ready():
	# Create and setup the shoot timer
	shoot_timer = Timer.new()
	shoot_timer.wait_time = shoot_interval
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	add_child(shoot_timer)
	
	# Find the player (assumes player is in group "player")
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	if not player:
		return
	
	# Check if player is in range
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= detection_range and can_shoot:
		shoot_at_player()

func shoot_at_player():
	if not projectile_scene or not player:
		return
	
	# Create projectile instance
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)  # Add to parent so it's not a child of enemy
	
	# Set projectile position
	projectile.global_position = global_position
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Set projectile velocity (assuming projectile has a velocity property)
	if projectile.has_method("set_direction"):
		projectile.set_direction(direction, projectile_speed)
	elif "velocity" in projectile:
		projectile.velocity = direction * projectile_speed
	
	# Start cooldown
	can_shoot = false
	shoot_timer.start()

func _on_shoot_timer_timeout():
	can_shoot = true
