extends RigidBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const MIN_VELOCITY = 80

func _on_mouse_entered() -> void:
	if linear_velocity.length() < MIN_VELOCITY:
		GameManager.add_mineral.emit(GameManager.Mineral.AMETHYST, 1)
		queue_free()
