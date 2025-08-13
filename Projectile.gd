# Projectile.gd
extends RigidBody2D


@export var lifetime: float = 5.0

var velocity: Vector2

func _ready():
	# Set up collision
	contact_monitor = true
	max_contacts_reported = 10
	body_entered.connect(_on_body_entered)
	
	# Auto-destroy after lifetime
	var timer = Timer.new()
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	timer.one_shot = true
	add_child(timer)
	timer.start()

func _physics_process(delta):
	# Move the projectile
	global_position += velocity * delta

func set_direction(direction: Vector2, speed: float):
	velocity = direction * speed
	# Optionally rotate the projectile to face movement direction
	rotation = direction.angle()

func _on_body_entered(body):
	if body.is_in_group("obstacle"):
		# Hit an obstacle, destroy projectile
		queue_free()
