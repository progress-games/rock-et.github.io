extends Node2D

const SCREEN_WIDTH := 320
const SCREEN_HEIGHT := 180
const SPAWN_INSET := 50
const POWERUP := preload("res://mission/powerups/powerup.tscn")

var powerup_timers: Array[Timer] = []

var powerup_spawn: Timer = Timer.new()

func _ready() -> void:
	if GameManager.planet != Enums.Planet.KRUOS:
		queue_free()
	
	powerup_spawn.wait_time = 0.5#StatManager.get_stat("powerup_spawn_rate").value
	powerup_spawn.timeout.connect(spawn_powerup)
	add_child(powerup_spawn)
	powerup_spawn.start()
	
	GameManager.powerup_hit.connect(powerup_hit)

func spawn_powerup() -> void:
	var new_powerup = POWERUP.instantiate() as Powerup
	
	if randf() < 0.5: # left
		new_powerup.position = Vector2(0, randi_range(SPAWN_INSET, SCREEN_HEIGHT - SPAWN_INSET))
		new_powerup.velocity = Vector2(100, 0)
	else: # right
		new_powerup.position = Vector2(SCREEN_WIDTH, randi_range(SPAWN_INSET, SCREEN_HEIGHT - SPAWN_INSET))
		new_powerup.velocity = Vector2(-100, 0)
	
	new_powerup.position -= Vector2(SCREEN_WIDTH / 2., SCREEN_HEIGHT / 2.)
	new_powerup.powerup_type = Powerup.PowerupType.values().pick_random()
	
	new_powerup.set_meta("powerup", true)
	add_child(new_powerup)

func powerup_hit(powerup: Powerup) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
	
	var new_timer = Timer.new()
	new_timer.wait_time = StatManager.get_stat("powerup_duration").value
	
	match powerup.powerup_type:
		Powerup.PowerupType.SPEED_BOOST:
			var particles = ParticleManager.get_particles(ParticleManager.ParticleType.SPEED_BOOST)
			particles.emitting = true
			particles.position = Vector2(0, -100)
			add_child(particles)
			
			StatManager.get_stat("thruster_speed").value += StatManager.get_stat("speed_boost").value
			new_timer.timeout.connect(func (): 
				StatManager.get_stat("thruster_speed").value -= StatManager.get_stat("speed_boost").value)
		Powerup.PowerupType.FUEL_BOOST:
			GameManager.time_added.emit(StatManager.get_stat("fuel_boost").value)
		Powerup.PowerupType.MORE_MINERALS:
			StatManager.get_stat("mineral_value").value += StatManager.get_stat("more_minerals").value
			new_timer.timeout.connect(func (): 
				StatManager.get_stat("mineral_value").value -= StatManager.get_stat("more_minerals").value)
		Powerup.PowerupType.DAMAGE_BOOST:
			StatManager.get_stat("hit_strength").value += StatManager.get_stat("damage_boost").value
			new_timer.timeout.connect(func (): 
				StatManager.get_stat("hit_strength").value -= StatManager.get_stat("damage_boost").value)
	
	add_child(new_timer)
	new_timer.start()
	powerup_timers.append(new_timer)
	new_timer.timeout.connect(func (): powerup_timers.erase(new_timer); new_timer.queue_free())
	
	var new_particles := ParticleManager.get_particles(ParticleManager.ParticleType.POWERUP)
	new_particles.emitting = true
	new_particles.position = powerup.position
	add_child(new_particles)
	
	powerup.queue_free()

func clean_up() -> void:
	for timer in powerup_timers:
		timer.timeout.emit()
		timer.stop()
