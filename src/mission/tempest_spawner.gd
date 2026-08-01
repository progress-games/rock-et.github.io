extends Node2D

const HAIL = preload("uid://cylvopk7u3kar")
const SNOW_TRAIL = preload("uid://bnn3inflimj44")
const UPDATE_DISTANCE = 3
const TICK_SPEED = 0.1

var collision_shapes: Array[CollisionShape2D]
var particles: Array[CPUParticles2D]
var last_pos := Vector2(0, 0)
var active = false
var damage_asteroids_timer

@onready var snow_trail: TextureRect = $Tempests/SnowTrail
@onready var hailstorm: TextureRect = $Tempests/Hailstorm

@onready var snow_trail_bg: ColorRect = $Tempests/SnowTrail/ColorRect
@onready var snow_trail_remaining: ColorRect = $Tempests/SnowTrail/ColorRect/ColorRect
@onready var snow_trail_spent: ColorRect = $Tempests/SnowTrail/ColorRect/ColorRect2

@onready var hailstorm_bg: ColorRect = $Tempests/Hailstorm/ColorRect2
@onready var hailstorm_remaining: ColorRect = $Tempests/Hailstorm/ColorRect2/ColorRect
@onready var hailstorm_spent: ColorRect = $Tempests/Hailstorm/ColorRect2/ColorRect2

# yeah bruv don't care
@onready var bullet_spawner: Node2D = $"../BulletSpawner"
@onready var area: Area2D = $Area2D

@onready var snow_trail_charge: float = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL,\
	TempestManager.StatType.CHARGE)
@onready var hailstorm_charge: float = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM,\
	TempestManager.StatType.CHARGE)
	
@onready var snow_trail_total_charge: float = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL,\
	TempestManager.StatType.CHARGE)
@onready var hailstorm_total_charge: float = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM,\
	TempestManager.StatType.CHARGE)

var hailstorm_interval: float = 0

func _ready() -> void:
	if !GameManager.planet == Enums.Planet.KRUOS || !GameManager.player.has_discovered_state(Enums.State.BUNKER): 
		queue_free()
	area.area_entered.connect(snow_entered)
	area.area_exited.connect(snow_exited)
	
	damage_asteroids_timer = Timer.new()
	damage_asteroids_timer.wait_time = TICK_SPEED
	damage_asteroids_timer.timeout.connect(damage_asteroids)
	add_child(damage_asteroids_timer)
	
	visualise_charge(snow_trail_bg, snow_trail_remaining, snow_trail_spent, 1.)
	visualise_charge(hailstorm_bg, hailstorm_remaining, hailstorm_spent, 1.)

func clear_snow_trail() -> void:
	particles.map(func (x: CPUParticles2D): 
		x.one_shot = true
		x.finished.connect(func (): particles.erase(x))
	)
	
	var t = Timer.new()
	t.wait_time = \
		TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.MELT) +\
		2
	t.one_shot = true
	t.timeout.connect(
		func ():
			if !active:
				collision_shapes.map(func (x): x.queue_free())
				collision_shapes.clear()
				damage_asteroids_timer.stop()
	)
	add_child(t)
	t.start()

func spawn_snow_trail() -> void:
	var mouse_pos = get_local_mouse_position()
	var dis = last_pos.distance_to(mouse_pos)
	
	if !active:
		active = true
		last_pos = mouse_pos
		collision_shapes.map(func (x): x.queue_free())
		collision_shapes.clear()
		damage_asteroids_timer.start()
	elif dis < UPDATE_DISTANCE:
		return
	
	create_collision_shape(mouse_pos)
	spawn_snow_particles(mouse_pos)
	
	last_pos = mouse_pos

func snow_entered(asteroid) -> void:
	if !asteroid.has_meta("asteroid"): return
	
	asteroid.speed_mult -= TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.SLOW_AMOUNT)
	asteroid.sprite.modulate.a -= 0.3

func snow_exited(asteroid) -> void:
	if !asteroid.has_meta("asteroid"): return
	
	asteroid.speed_mult += TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.SLOW_AMOUNT)
	asteroid.sprite.modulate.a += 0.3

func damage_asteroids() -> void:
	var asteroids = area.get_overlapping_areas().filter(func (x): return x.has_meta("asteroid"))
	if asteroids.size() == 0: return
	var dmg = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.DAMAGE)
	for a in asteroids:
		a.hit(dmg, false)

func spawn_snow_particles(mouse_pos: Vector2) -> void:
	var new = SNOW_TRAIL.instantiate() as CPUParticles2D
	new.emitting = true
	new.position = mouse_pos
	new.emission_sphere_radius = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.WIDTH)
	new.amount = new.amount * ceil(new.emission_sphere_radius / 10.)
	new.lifetime = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.MELT)
	add_child(new)
	particles.append(new)

func create_collision_shape(mouse_pos: Vector2) -> void:
	var collision_shape = CollisionShape2D.new()
	collision_shape.position = mouse_pos
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = TempestManager.get_stat(TempestManager.TempestType.SNOW_TRAIL, TempestManager.StatType.WIDTH)
	
	area.add_child(collision_shape)
	collision_shapes.append(collision_shape)

func spawn_hail() -> void:
	var spawn_rate = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM, \
		TempestManager.StatType.SPAWN_RATE)
	
	if hailstorm_interval < spawn_rate:
		return
	
	hailstorm_interval = 0
	var b = bullet_spawner.spawn_bullet(Vector2(randi_range(-150, 150), -90), PI / 2)
	b.hit_data.damage_mult = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM, \
		TempestManager.StatType.DAMAGE)
	b.hit_data.freeze_dur = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM, \
		TempestManager.StatType.FREEZE_DURATION)
	b.pierce = TempestManager.get_stat(TempestManager.TempestType.HAILSTORM, \
		TempestManager.StatType.PIERCE)
	b.set_texture(ImageTexture.create_from_image(HAIL.get_image()))

func visualise_charge(bg_rect: ColorRect, remaining: ColorRect, spent: ColorRect, progress: float) -> void:
	var width = bg_rect.size.x - 2 # -2 for borders
	var remaining_width = progress * width
	var spent_width = width - remaining_width - (1 if progress > 0 else 0) # -1 for middle separator
	
	remaining.size.x = remaining_width
	spent.position.x = remaining.position.x + remaining_width + (1 if progress > 0 else 0)
	spent.size.x = spent_width

func _process(d: float) -> void:
	if Input.is_action_pressed("potion slot 1") && snow_trail_charge > 0:
		spawn_snow_trail()
		
		snow_trail_charge -= d
		visualise_charge(snow_trail_bg, snow_trail_remaining, snow_trail_spent, \
			snow_trail_charge / snow_trail_total_charge)
		if snow_trail_charge <= 0:
			snow_trail.modulate.a = 0.5
	elif Input.is_action_pressed("potion slot 2") && hailstorm_charge > 0:
		spawn_hail()
		
		hailstorm_interval += d
		hailstorm_charge -= d
		visualise_charge(hailstorm_bg, hailstorm_remaining, hailstorm_spent, \
			hailstorm_charge / hailstorm_total_charge)
		if hailstorm_charge <= 0:
			hailstorm.modulate.a = 0.5
	elif active:
		clear_snow_trail()
		active = false
