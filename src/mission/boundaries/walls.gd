extends Area2D

func _on_area_entered(area: Area2D) -> void:
	var velocity: Vector2 = area.linear_velocity
	var normal := get_collision_normal(area)
	
	area.linear_velocity = velocity.bounce(normal)

func get_collision_normal(area: Area2D) -> Vector2:
	var delta = area.global_position - global_position
	
	# Determine which axis was penetrated more
	if abs(delta.x) > abs(delta.y):
		# Left/right hit
		return Vector2.RIGHT if delta.x < 0 else Vector2.LEFT
	else:
		# Top/bottom hit
		return Vector2.DOWN if delta.y < 0 else Vector2.UP
