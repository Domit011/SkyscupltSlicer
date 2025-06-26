extends CharacterBody2D

# Movement variables
@export var move_speed: float = 400.0 # Left-right speed in pixels/second
@export var upward_speed: float = 100.0 # Upward speed in pixels/second
@export var game_manager : Node2D

# Signal for item delivery
signal item_delivered

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
	if body.is_in_group("Obstacle"):
		print("you die")
		game_manager.game_over()
	elif body.is_in_group("DropOff"):
		print("📦 Entered drop-off zone!")
		# Emit signal to game manager to handle delivery
		item_delivered.emit()

# Alternative method if you prefer Area2D detection instead of body_entered
func _on_hit_box_area_entered(area: Area2D) -> void:
	if area.is_in_group("DropOff"):
		print("📦 Entered drop-off zone!")
		# Emit signal to game manager to handle delivery
		item_delivered.emit()
