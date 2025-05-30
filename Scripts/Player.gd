extends CharacterBody2D

# Movement variables
@export var move_speed: float = 200.0 # Left-right speed in pixels/second
@export var upward_speed: float = 100.0 # Upward speed in pixels/second

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
