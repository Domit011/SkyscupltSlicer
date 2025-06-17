extends CharacterBody2D

@export var min_speed: float = -100.0  # Minimum horizontal speed
@export var max_speed: float = -125.0  # Maximum horizontal speed
@export var speed_change_interval: float = 1.0  # How often to change speed (seconds)
@export var sine_amplitude: float = 50.0  # How far the sine wave deviates vertically
@export var sine_frequency: float = 2.0  # How fast the sine wave oscillates
var time: float = 0.0
var current_speed: float
var speed_timer: float = 0.0
var start_position: Vector2
var screen_width: float

func _ready():
	# Get screen width for off-screen check
	screen_width = get_viewport_rect().size.x
	start_position = global_position
	
	# Initialize with a random speed
	current_speed = randf_range(min_speed, max_speed)

func _physics_process(delta):
	# Increment time for sine wave calculation
	time += delta * sine_frequency
	
	# Update speed timer
	speed_timer += delta
	
	# Change speed at intervals
	if speed_timer >= speed_change_interval:
		current_speed = randf_range(min_speed, max_speed)
		speed_timer = 0.0
	
	# Calculate sine wave offset for Y-axis
	var sine_offset = sin(time) * sine_amplitude
	
	# Set velocity: move horizontally with sine wave vertical movement
	velocity = Vector2(current_speed, sine_offset)
	
	# Move the character
	move_and_slide()
	
	# Check if off-screen (moving left with negative speed)
	if global_position.x < -100:  # Remove when 100 pixels off the left edge of screen
		queue_free()  # Remove the node when off-screen
