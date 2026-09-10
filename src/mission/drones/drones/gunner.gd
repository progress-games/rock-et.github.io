extends Drone

func shoot() -> void:
	current_ammo -= 1
	shot.emit(create_bullet())
