extends Drone

func shoot() -> void:
	super.shoot()
	
	current_ammo -= 1
	var b = create_bullet()
	b.hit_data.burn_dur = 2.
	b.hit_data.burn_damage = drone_stats.get_stat(DroneEnums.StatType.BURN_DAMAGE)
	shot.emit(b)
