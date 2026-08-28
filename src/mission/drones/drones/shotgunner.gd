extends Drone

const BULLETS := 6

func shoot() -> void:
	super.shoot()
	
	for i in range(min(BULLETS, current_ammo)):
		current_ammo -= 1
		shot.emit(create_bullet())
