extends Drone

const CLICK_BOX = preload("uid://by200eutp0c4c")

func shoot() -> void:
	super.shoot()
	
	current_ammo -= 1
	var b = create_bullet()
	b.collided.connect(
		func (a: Asteroid):
			call_deferred("create_explosion", a)
	)
	shot.emit(b)

func create_explosion(a: Asteroid) -> void:
	var new = CLICK_BOX.instantiate()
	new.click_effect = ClickEffectManager.ClickType.EXPLOSION
	get_parent().get_parent().add_child(new)
	new.global_position = a.global_position
	new.lighten_borders = false
	
	new.damage_override = drone_stats.get_stat(DroneEnums.StatType.EXPLOSION_DAMAGE)
	new.size_override = drone_stats.get_stat(DroneEnums.StatType.EXPLOSION_SIZE)
	
	new.exploded.connect(increase_dealt)
