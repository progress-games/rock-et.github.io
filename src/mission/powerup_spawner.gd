extends Node2D

const SCREEN_WIDTH := 320
const SCREEN_HEIGHT := 180
const SPAWN_INSET := 50
const POWERUP := preload("res://mission/powerups/powerup.tscn")
const POWERUP_DURATION := 3.

var powerup_timers: Array[Timer] = []

var powerup_spawn: Timer = Timer.new()

func _ready() -> void:
	if GameManager.planet != Enums.Planet.KRUOS:
		queue_free()
	
	powerup_spawn.wait_time = StatManager.get_stat("powerup_spawn_rate").value
	powerup_spawn.timeout.connect(spawn_powerup)
	add_child(powerup_spawn)
	if StatManager.enabled_powerups.size() > 0:
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
	
	new_powerup.super_powerup = randf() <= StatManager.get_stat("powerup_ultra_chance").value
	new_powerup.position -= Vector2(SCREEN_WIDTH / 2., SCREEN_HEIGHT / 2.)
	new_powerup.powerup_type = StatManager.enabled_powerups.pick_random()

	new_powerup.set_meta("powerup", true)
	add_child(new_powerup)

func new_timer(powerup_type: Powerup.PowerupType, subtraction_amount: float) -> void:
	var t = Timer.new()
	t.wait_time = POWERUP_DURATION
	add_child(t)
	t.start()
	powerup_timers.append(t)
	t.timeout.connect(func (): 
		powerup_timers.erase(t)
		t.queue_free()
		GameManager.powerup_modifiers[powerup_type] = max(0, GameManager.powerup_modifiers[powerup_type] - subtraction_amount))

func powerup_hit(powerup: Powerup) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.POP)
	
	var super_mult = 3 if powerup.super_powerup else 1
	
	"""
	SPEED_BOOST, # temp boost
	DOUBLE_MINERALS, # next n minerals drop double
	DOUBLE_CLICK, # next n clicks are double clicks
	INSTA_BREAK, # next n rocks are instantly broken
	MORE_ROCKS, # next rock broken spawns n additional new rocks
	PAUSE, # all rocks are frozen for n seconds
	EXPLOSION, # creates an explosion click box
	SIZE_UP, # target size up
	AUTOCLICK, # autoclicks your cursor every n seconds
	"""
	
	match powerup.powerup_type:
		Powerup.PowerupType.SPEED_BOOST:
			var particles = ParticleManager.get_particles(ParticleManager.ParticleType.SPEED_BOOST)
			particles.emitting = true
			particles.one_shot = true
			particles.position = Vector2(0, -100)
			particles.lifetime = POWERUP_DURATION
			particles.finished.connect(func (): particles.queue_free())
			add_child(particles)
			
			GameManager.powerup_modifiers[powerup.powerup_type] += \
				(StatManager.get_stat("speed_boost_powerup").value * super_mult) / POWERUP_DURATION
			
			new_timer(Powerup.PowerupType.SPEED_BOOST, 
			StatManager.get_stat("speed_boost_powerup").value * super_mult / POWERUP_DURATION)
		Powerup.PowerupType.DOUBLE_MINERALS:
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("double_minerals_powerup").value * super_mult
		Powerup.PowerupType.DOUBLE_CLICK:
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("double_click_powerup").value * super_mult
		Powerup.PowerupType.INSTA_BREAK: 
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("insta_break_powerup").value * super_mult
		Powerup.PowerupType.MORE_ROCKS:
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("more_rocks_powerup").value * super_mult
		Powerup.PowerupType.PAUSE: 
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("pause_powerup").value * super_mult
			new_timer(Powerup.PowerupType.PAUSE, StatManager.get_stat("pause_powerup").value * super_mult)
		Powerup.PowerupType.SIZE_UP: 
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("size_up_powerup").value * super_mult
			new_timer(Powerup.PowerupType.SIZE_UP, StatManager.get_stat("size_up_powerup").value * super_mult)
		Powerup.PowerupType.AUTOCLICK:
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("autoclick_powerup").value * super_mult
			new_timer(Powerup.PowerupType.AUTOCLICK, StatManager.get_stat("autoclick_powerup").value * super_mult)
	
	var new_particles := ParticleManager.get_particles(ParticleManager.ParticleType.POWERUP)
	new_particles.emitting = true
	new_particles.position = powerup.position
	add_child(new_particles)
	
	powerup.queue_free()

func clean_up() -> void:
	for timer in powerup_timers:
		timer.timeout.emit()
		timer.stop()
