extends Drone

var hit_asteroids: Dictionary[int, bool]

func shoot() -> void:
	super.shoot()
	
	current_ammo -= 1
	var b = create_bullet()
	b.hit_data.burn_dur = 2.
	b.hit_data.burn_damage = drone_stats.get_stat(DroneEnums.StatType.BURN_DAMAGE)
	shot.emit(b)
	b.collided.connect(
		func (a: Asteroid):
			if !hit_asteroids.has(a.get_instance_id()):
				a.taken_burn_damage.connect(increase_dealt)
				hit_asteroids.set(a.get_instance_id(), true)
	)
