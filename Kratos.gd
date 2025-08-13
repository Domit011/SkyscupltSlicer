extends CharacterBody2D

# Earth's gravity in m/s²
const EARTH_GRAVITY = 9.81

# Scale factor to convert from real-world units to pixels
# Adjust this based on your game's scale (e.g., 1 meter = 100 pixels)
const PIXELS_PER_METER = 100.0

# Calculate gravity in pixels per second squared
const GRAVITY = EARTH_GRAVITY * PIXELS_PER_METER

# Visibility detection variables
var can_fall = false
var visibility_notifier: VisibleOnScreenNotifier2D

func _ready():
	# Create and setup visibility notifier
	visibility_notifier = VisibleOnScreenNotifier2D.new()
	add_child(visibility_notifier)
	
	# Connect the screen_entered signal to start falling
	if not visibility_notifier.screen_entered.is_connected(_on_screen_entered):
		visibility_notifier.screen_entered.connect(_on_screen_entered)
	
	# Optionally connect screen_exited if you want to stop falling when off-screen
	# visibility_notifier.screen_exited.connect(_on_screen_exited)
	
	print("✅ Visibility detection setup complete - waiting for CharacterBody2D to become visible")

func _on_screen_entered():
	"""Called when the CharacterBody2D becomes visible on screen"""
	print("👁️ CharacterBody2D is now visible! Starting gravity...")
	can_fall = true

func _on_screen_exited():
	"""Optional: Called when CharacterBody2D exits screen"""
	print("👁️ CharacterBody2D left the screen")
	# Uncomment if you want to stop falling when off-screen:
	# can_fall = false

func _physics_process(delta):
	# Apply gravity to vertical velocity only when visible
	if can_fall and not is_on_floor():
		velocity.y += GRAVITY * delta
	
	# Move the character
	move_and_slide()

# Optional: Add a jump function
func jump(jump_force: float = 500.0):
	if can_fall and is_on_floor():
		velocity.y = -jump_force

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
