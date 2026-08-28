extends Drone

func shoot() -> void:
	super.shoot()
	
	current_ammo -= 1
	shot.emit(create_bullet())
