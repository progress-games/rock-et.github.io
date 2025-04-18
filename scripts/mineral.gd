extends RigidBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const MIN_VELOCITY = 50

func _on_mouse_entered() -> void:
	if linear_velocity.length() < MIN_VELOCITY:
		GameManager.add_point.emit(1)
		queue_free()
