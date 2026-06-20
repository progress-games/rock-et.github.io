extends Area2D

@onready var collision_shape = $CollisionShape2D

func body_fully_inside(body: RigidBody2D) -> bool:
	var body_shape = body.collision_shape.shape
	var area_shape = collision_shape.shape
	
	var body_transform = body.get_global_transform()
	var area_transform = collision_shape.get_global_transform()
	
	var body_rect = Rect2(
		body_transform.origin - body_shape.extents,
		body_shape.extents * 2
	)
	
	var area_rect = Rect2(
		area_transform.origin - area_shape.extents,
		area_shape.extents * 2
	)
	
	return area_rect.encloses(body_rect)

func _on_body_exited(body: Node2D) -> void:
	body.queue_free()

func _on_area_exited(area: Area2D) -> void:
	area.queue_free()


func _on_walls_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
