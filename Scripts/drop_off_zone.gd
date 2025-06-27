extends Area2D
class_name DropOffZone

# Visual feedback
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var label: Label = $Label

# Zone properties
@export var zone_name: String = "Drop Zone"
@export var delivery_sound: AudioStream
@export var highlight_color: Color = Color.GREEN
@export var normal_color: Color = Color.WHITE

# Audio player for delivery sound
var audio_player: AudioStreamPlayer2D

# Track if player is in zone
var player_in_zone: bool = false
var player_reference: CharacterBody2D = null

func _ready() -> void:
	# Setup the zone
	setup_zone()
	
	# Connect area signals
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	
	# Create audio player for delivery sound
	audio_player = AudioStreamPlayer2D.new()
	add_child(audio_player)
	if delivery_sound:
		audio_player.stream = delivery_sound
	
	print("✅ DropOffZone '", zone_name, "' initialized successfully")

func setup_zone() -> void:
	"""Setup the visual appearance of the drop-off zone"""
	
	# Setup sprite if it exists
	if sprite:
		sprite.modulate = normal_color
	
	# Setup label if it exists
	if label:
		label.text = zone_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Ensure collision shape exists
	if not collision_shape:
		print("⚠️ Warning: DropOffZone missing CollisionShape2D!")

func _on_body_entered(body: Node2D) -> void:
	"""Called when a body enters the drop-off zone"""
	print("🚪 Body entered drop-off zone: ", body.name)
	
	# Check if it's the player
	if body.name == "Player" or body is CharacterBody2D:
		player_in_zone = true
		player_reference = body
		
		# Visual feedback - highlight the zone
		highlight_zone(true)
		
		# Try to deliver items automatically
		attempt_delivery()
		
		print("✅ Player entered drop-off zone: ", zone_name)

func _on_body_exited(body: Node2D) -> void:
	"""Called when a body exits the drop-off zone"""
	print("🚪 Body exited drop-off zone: ", body.name)
	
	# Check if it's the player leaving
	if body == player_reference:
		player_in_zone = false
		player_reference = null
		
		# Remove visual feedback
		highlight_zone(false)
		
		print("❌ Player left drop-off zone: ", zone_name)

func highlight_zone(highlight: bool) -> void:
	"""Provide visual feedback when player is in zone"""
	if sprite:
		if highlight:
			sprite.modulate = highlight_color
			# Optional: Add scaling effect
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.2)
		else:
			sprite.modulate = normal_color
			# Reset scale
			var tween = create_tween()
			tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)

func attempt_delivery() -> void:
	"""Attempt to deliver items when player enters zone"""
	if not player_reference:
		return
	
	# Check if player has the item_delivered signal
	if player_reference.has_signal("item_delivered"):
		print("📤 Triggering item delivery...")
		player_reference.emit_signal("item_delivered")
		
		# Play delivery sound
		play_delivery_sound()
		
		# Optional: Add visual effect
		show_delivery_effect()
	else:
		print("⚠️ Warning: Player doesn't have 'item_delivered' signal!")

func play_delivery_sound() -> void:
	"""Play the delivery confirmation sound"""
	if audio_player and delivery_sound:
		audio_player.play()
		print("🔊 Playing delivery sound")

func show_delivery_effect() -> void:
	"""Show a visual effect when delivery occurs"""
	# Create a simple flash effect
	if sprite:
		var original_modulate = sprite.modulate
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite, "modulate", original_modulate, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
		tween.tween_property(sprite, "modulate", original_modulate, 0.1)

# Optional: Manual delivery trigger (if you want button-based delivery instead)
func manual_delivery() -> void:
	"""Manually trigger delivery - call this if you want button-based delivery"""
	if player_in_zone and player_reference:
		attempt_delivery()
	else:
		print("❌ No player in zone for manual delivery")

# Utility function to check if zone is occupied
func is_player_in_zone() -> bool:
	return player_in_zone

# Utility function to get the player reference
func get_player_in_zone() -> CharacterBody2D:
	return player_reference
