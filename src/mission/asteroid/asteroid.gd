extends RigidBody2D
class_name Asteroid

const LIGHTER_HITS := Color(0.498, 0.439, 0.541, 1.0)
const MIN_SPEED = 50
const FRICTION = 0.9
const TEXTURE_DIMENSIONS = 38
const FROZEN := Color(0.302, 0.608, 0.902, 1.0)

@onready var sprite: Sprite2D = $Sprite2D
@onready var flash_sprite: Sprite2D = $Flash
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_bar: ColorRect = $HitBar

var velocity := Vector2(0, 0)
var rotation_speed = randf_range(-3, 3)

var base_scale: Vector2
var hitflash: Timer
var frozen_timer: Timer

@export var hitflash_dur: float

var hits: float
var level: int
var data: AsteroidData
var asteroid_type: Enums.Asteroid
var erraticness: float
var erratic_timer: Timer = Timer.new()
var lighten_hits: bool = false # lightens hitbar for darker bgs

var paused_velocity: Vector2
var paused_angular: float

var frozen_velocity: Vector2
var frozen_angular: float

var paused: bool = false
var frozen: bool = false
var broken: bool = false

signal asteroid_broken(asteroid: Asteroid)

func _ready() -> void:
	set_meta("asteroid", true)
	
	_set_region()
	erraticness = GameManager.get_item_stat("target_practice", "erratic_movement")
	erraticness += DrinksManager.get_stat(DrinkModifier.ModifyingStat.ERRATIC_ASTEROIDS)
	
	hits = data.hits[level]
	asteroid_type = data.asteroid_type
	
	base_scale = sprite.scale
	z_index = 1
	
	linear_velocity = velocity
	angular_velocity = rotation_speed
	if erraticness > 1:
		erratic_timer.wait_time = 1 / erraticness
		erratic_timer.timeout.connect(func ():
			linear_velocity += Vector2(
				erraticness * randf_range(-100, 100),
				erraticness * randf_range(-100, 100) 
			)
		)
		add_child(erratic_timer)
		erratic_timer.start(randf_range(0.1, 1 / erraticness))
	
	hitflash = Timer.new()
	hitflash.wait_time = hitflash_dur
	hitflash.one_shot = true
	hitflash.timeout.connect(reset_hitflash)
	add_child(hitflash)
	reset_hitflash()
	
	frozen_timer = Timer.new()
	frozen_timer.wait_time = StatManager.get_stat("freeze_duration").value
	frozen_timer.one_shot = true
	frozen_timer.timeout.connect(set_unfrozen)
	add_child(frozen_timer)

func set_frozen() -> void:
	sprite.modulate = FROZEN
	freeze = true
	frozen = true
	frozen_angular = paused_angular if paused else angular_velocity
	frozen_velocity = paused_velocity if paused else linear_velocity
	
	frozen_timer.start()

func set_unfrozen() -> void:
	sprite.modulate = Color.WHITE
	freeze = false
	frozen = false
	
	if paused: return
	linear_velocity = frozen_velocity
	angular_velocity = frozen_angular

func reset_hitflash() -> void:
	flash_sprite.hide()
	sprite.show()

func _physics_process(_delta: float) -> void:
	if GameManager.powerup_modifiers[Powerup.PowerupType.PAUSE] > 0 and !paused:
		paused_velocity = linear_velocity if !frozen else frozen_velocity
		paused_angular = angular_velocity if !frozen else frozen_angular
		
		freeze = true
		paused = true
	else:
		if paused:
			if !frozen:
				linear_velocity = paused_velocity
				angular_velocity = paused_angular
			paused = false
			freeze = false
		if linear_velocity.length() > MIN_SPEED:
			linear_velocity *= FRICTION

func hit(strength: float) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_ROCK)
	
	sprite.hide()
	flash_sprite.show()
	
	hitflash.stop()
	hitflash.start()
	
	var new_particles = ParticleManager.get_particles(ParticleManager.ParticleType.ROCK_HIT)
	new_particles.global_position = global_position
	get_tree().current_scene.add_child(new_particles)
	new_particles.emitting = true
	
	hits -= strength
	
	hit_bar.visible = strength > 0 or hit_bar.visible
	hit_bar.material.set_shader_parameter("progress", hits / data.hits[level])
	
	if hits <= 0:
		broken = true
		break_asteroid()

func break_asteroid() -> void:
	asteroid_broken.emit(self)
	hitflash.stop()
	queue_free()

func _set_region() -> void:
	var region := Rect2(
		level * TEXTURE_DIMENSIONS,
		0,
		TEXTURE_DIMENSIONS,
		TEXTURE_DIMENSIONS
	)
	
	var texture = AtlasTexture.new()
	texture.atlas = data.texture
	texture.set_region(region)
	
	var i = texture.get_image().get_used_rect()
	var h = hit_bar
	var x = Vector2(10, 10)
	
	sprite.texture = texture
	sprite.modulate = Color.WHITE
	flash_sprite.texture = texture
	flash_sprite.material = flash_sprite.material.duplicate()
	collision_shape.shape.size = i.size
	
	h.material = h.material.duplicate()
	
	h.position -= (Vector2(i.size) + x) / 2
	h.size = Vector2(i.size) + x
	if lighten_hits:
		h.color = LIGHTER_HITS
