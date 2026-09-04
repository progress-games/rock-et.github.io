extends Drone

func shoot() -> void:
	super.shoot()
	
	var bullets = min(drone_stats.get_stat(DroneEnums.StatType.BULLETS_PER_SHOT), current_ammo)
	
	for i in range(bullets):
		current_ammo -= 1
		var b = create_bullet()
		shot.emit(b)
		b.rotation += (i / bullets) * 2 * PI
