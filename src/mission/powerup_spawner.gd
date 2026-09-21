extends Node2D

const SCREEN_WIDTH := 320
const SCREEN_HEIGHT := 180
const SPAWN_INSET := 50
const POWERUP := preload("res://mission/powerups/powerup.tscn")
const POWERUP_DURATION := 3.
const LASER = preload("uid://dpyw4c1t85bn1")
const LOCK_ON = preload("uid://d2rxm2wfwhmvy")
const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const LOCK_ON_OUTLINE = Color(0.18, 0.133, 0.184, 1.0)

const EXPLOSION_DAMAGE = 8

var powerup_timers: Array[Timer] = []

var powerup_spawn: Timer = Timer.new()

var lock_on_points: Array[Vector2]

@onready var asteroid_spawner: Node2D = $"../AsteroidSpawner"
@onready var click_effect_spawner: Node2D = $"../ClickEffectSpawner"
@onready var lock_on: Node2D = $LockOn

func _ready() -> void:
	if GameManager.planet != Enums.Planet.KRUOS:
		queue_free()
	
	powerup_spawn.wait_time = StatManager.get_stat("powerup_spawn_rate").value
	powerup_spawn.timeout.connect(spawn_powerup)
	add_child(powerup_spawn)
	if StatManager.enabled_powerups.size() > 0:
		powerup_spawn.start()
	
	GameManager.powerup_hit.connect(powerup_hit)
	
	click_effect_spawner.click_effect_spawned.connect(update_lock_on_pos)

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
	
	if new_powerup.super_powerup:
		new_powerup.velocity *= 2.

	new_powerup.set_meta("powerup", true)
	add_child(new_powerup)

func new_timer(powerup_type: Powerup.PowerupType, subtraction_amount: float, duration: float = POWERUP_DURATION) -> void:
	var t = Timer.new()
	t.wait_time = duration
	add_child(t)
	t.start()
	powerup_timers.append(t)
	t.timeout.connect(func (): 
		powerup_timers.erase(t)
		t.queue_free()
		#print_debug(GameManager.powerup_modifiers[powerup_type], ", ", subtraction_amount)
		GameManager.powerup_modifiers[powerup_type] = \
			max(0, GameManager.powerup_modifiers[powerup_type] - subtraction_amount))

func spawn_lasers(amount: float) -> void:
	var delay = 0.2
	
	for i in range(int(ceil(amount))):
		var t = create_tween()
		t.tween_property(self, "rotation", rotation, delay * i)
		t.finished.connect(
			func ():
				var new_laser = LASER.instantiate()
				
				new_laser.position.x = randi_range(-140, 140)
				new_laser.rotation_degrees = randi_range(-30, 30)
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.LASER)
				
				add_child(new_laser)
		)

func powerup_hit(powerup: Powerup) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.POP)
	
	var super_mult = 3 if powerup.super_powerup else 1
	
	"""
	SPEED_BOOST, # temp boost
	DOUBLE_MINERALS, # next n minerals drop double
	SNOW_TRAIL, # next n clicks are double clicks
	INSTA_BREAK, # next n rocks are instantly broken
	MORE_ROCKS, # next rock broken spawns n additional new rocks
	PAUSE, # all rocks are frozen for n seconds
	EXPLOSION, # creates an explosion click box
	SIZE_UP, # target size up
	AUTOCLICK, # autoclicks your cursor every n seconds
	"""
	
	match powerup.powerup_type:
		Powerup.PowerupType.SNOW_TRAIL:
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("snow_trail_powerup").value * super_mult
			new_timer(Powerup.PowerupType.SNOW_TRAIL, StatManager.get_stat("snow_trail_powerup").value * super_mult)
		Powerup.PowerupType.MORE_ROCKS:
			for i in range(StatManager.get_stat("more_rocks_powerup").value * super_mult):
				asteroid_spawner.spawn_new_asteroid(false, powerup.position, 0, false, 50)
		Powerup.PowerupType.SIZE_UP: 
			GameManager.powerup_modifiers[powerup.powerup_type] += StatManager.get_stat("size_up_powerup").value * super_mult
		Powerup.PowerupType.LASER:
			spawn_lasers(StatManager.get_stat("laser_powerup").value * super_mult)
		Powerup.PowerupType.EXPLOSION:
			var default_size = 20 # the default clickbox size
			click_effect_spawner.spawn_click_effect(
				ClickEffectManager.ClickType.EXPLOSION,
				powerup.position,
				EXPLOSION_DAMAGE,
				StatManager.get_stat("explosion_powerup").value / default_size)
		Powerup.PowerupType.LOCK_ON:
			for i in range(ceil(StatManager.get_stat("lock_on_powerup").value) * super_mult):
				GameManager.lock_on_positions.append(powerup.position)
			update_lock_on_pos()
		Powerup.PowerupType.TIPSY:
			GameManager.powerup_modifiers[powerup.powerup_type] += 2.
			new_timer(Powerup.PowerupType.TIPSY, 2., StatManager.get_stat("tipsy_powerup").value * super_mult)
		Powerup.PowerupType.GOLDEN_ASTEROID:
			for i in range(ceil(StatManager.get_stat("golden_asteroid_powerup").value * super_mult)):
				asteroid_spawner.spawn_new_asteroid(false, Vector2.ZERO, -1, true, 100)
	
	var new_particles := ParticleManager.get_particles(ParticleManager.ParticleType.POWERUP)
	new_particles.emitting = true
	new_particles.position = powerup.position
	add_child(new_particles)
	
	powerup.queue_free()

func clean_up() -> void:
	for timer in powerup_timers:
		timer.stop()
		timer.timeout.emit()

func update_lock_on_pos() -> void:
	lock_on.get_children().map(func (x): x.queue_free())
	
	if GameManager.lock_on_positions.size() == 0:
		return
	
	var shader = ShaderMaterial.new()
	shader.shader = WHITE_OUTLINE
	
	var unique_pos: Dictionary[Vector2, bool] = {}
	var first_pos: bool = true
	
	for pos in GameManager.lock_on_positions:
		if unique_pos.has(pos):
			continue
		
		unique_pos.set(pos, true)
		
		var s = Sprite2D.new()
		s.texture = LOCK_ON
		s.material = shader.duplicate()
		s.material.set_shader_parameter("color", LOCK_ON_OUTLINE)
		s.material.set_shader_parameter("pattern", 1)
		s.position = pos
		
		if !first_pos:
			s.modulate = Color(1, 1, 1, 0.3)
		
		first_pos = false
		
		lock_on.add_child(s)
		
