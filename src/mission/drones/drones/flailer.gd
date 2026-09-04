extends Drone

func shoot() -> void:
	super.shoot()
	
	reload_timer = 1
	
	current_ammo -= 1
	var b = create_bullet()
	b.rotate_around = self
	shot.emit(b)
	b.ready.connect(func (): b.sprite_2d.scale *= 2.)
