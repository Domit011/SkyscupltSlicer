extends CharacterBody2D

# Earth's gravity in m/s²
const EARTH_GRAVITY = 9.81
# Scale factor to convert from real-world units to pixels
# Adjust this based on your game's scale (e.g., 1 meter = 100 pixels)
const PIXELS_PER_METER = 100.0
# Calculate gravity in pixels per second squared
const GRAVITY = EARTH_GRAVITY * PIXELS_PER_METER

# Screen boundaries for random spawning
const MIN_X = 250
const MAX_X = 1000

# Visibility detection variables
var can_fall = false
var visibility_notifier: VisibleOnScreenNotifier2D

func _ready():
	# Set random spawn position
	set_random_spawn_position()
	
	# Create and setup visibility notifier
	visibility_notifier = VisibleOnScreenNotifier2D.new()
	add_child(visibility_notifier)
	
	# Connect the screen_entered signal to start falling
	if not visibility_notifier.screen_entered.is_connected(_on_screen_entered):
		visibility_notifier.screen_entered.connect(_on_screen_entered)
	
	# Optionally connect screen_exited if you want to stop falling when off-screen
	# visibility_notifier.screen_exited.connect(_on_screen_exited)
	
	print("✅ Visibility detection setup complete - waiting for CharacterBody2D to become visible")
	print("📍 Spawned at position: ", global_position)
	print("🔍 Debug - checking children:")
	for child in get_children():
		print("  - Child: ", child.name, " at position: ", child.position)

func set_random_spawn_position():
	"""Set the object to spawn at a random x position between 0 and 1250"""
	var random_x = randf_range(MIN_X, MAX_X)
	# Use global_position to ensure it spawns in world coordinates
	global_position.x = random_x
	print("🎲 Set random X position to: ", random_x)
	print("📍 Full global position: ", global_position)
	# Start falling immediately
	can_fall = true

func spawn_at_random_x(y_position: float = -100):
	"""Public function to respawn the object at a new random x position"""
	var random_x = randf_range(MIN_X, MAX_X)
	# Use global_position for world coordinates
	global_position = Vector2(random_x, global_position.y)  # Keep current Y, only change X
	velocity = Vector2.ZERO
	can_fall = true
	print("🎲 Respawned at random position: ", global_position)

func _on_screen_entered():
	print("👁️ CharacterBody2D is now visible! Starting gravity...")
	can_fall = true

func _on_screen_exited():
	print("👁️ CharacterBody2D left the screen")
	# Uncomment if you want to stop falling when off-screen:
	# can_fall = false

func _physics_process(delta):
	# Apply gravity to vertical velocity only when visible
	if can_fall and not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Move the character
	move_and_slide()

# Optional: Reset function to stop falling and reset visibility
func reset():
	velocity = Vector2.ZERO
	can_fall = false

# Optional: Force falling to start immediately
func start_falling():
	can_fall = true

# Optional: Check if the character is currently visible
func is_visible_on_screen() -> bool:
	return visibility_notifier.is_on_screen() if visibility_notifier else false
