extends Area2D
class_name Asteroid

const SLOW_AMOUNT := 0.15
const LIGHTER_HITS := Color(0.498, 0.439, 0.541, 1.0)
const FORTIFIED := Color(0.608, 0.671, 0.698, 1.0)
const DEFAULT := Color(0.18, 0.133, 0.184, 1.0)
const MIN_SPEED = 50
const FRICTION = 0.9
const TEXTURE_DIMENSIONS = 38
const FROZEN := Color(0.302, 0.608, 0.902, 1.0)

@onready var sprite: Sprite2D = $Sprite2D
@onready var flash_sprite: Sprite2D = $Flash
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hit_bar: ColorRect = $HitBar
@onready var fortified: TextureRect = $Fortified

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

var frozen: bool = false
var broken: bool = false
var speed_mult: float = 1.

signal asteroid_broken(asteroid: Asteroid)

func _ready() -> void:
	set_meta("asteroid", true)
	
	_set_region()
	erraticness = 1
	if GameManager.player.has_equipped("target_practice"):
		erraticness += 0.5
	erraticness += DrinksManager.get_stat(DrinkModifier.ModifyingStat.ERRATIC_ASTEROIDS)
	
	
	hits = data.hits[level]
	asteroid_type = data.asteroid_type
	
	if GameManager.player.has_equipped("fortified"): 
		hits *= 1.51
	
	base_scale = sprite.scale
	z_index = 1
	
	if erraticness > 1:
		erratic_timer.wait_time = 1 / erraticness
		erratic_timer.timeout.connect(func ():
			velocity += Vector2(
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
	frozen_timer.one_shot = true
	frozen_timer.timeout.connect(set_unfrozen)
	add_child(frozen_timer)

func set_frozen(dur: float = StatManager.get_stat("freeze_duration").value) -> void:
	sprite.modulate = FROZEN
	frozen = true
	
	frozen_timer.wait_time = dur
	frozen_timer.start()

func set_unfrozen() -> void:
	sprite.modulate = Color.WHITE
	frozen = false

func reset_hitflash() -> void:
	flash_sprite.hide()
	sprite.show()

func _process(delta: float) -> void:
	if frozen: return
	
	var slowed = GameManager.powerup_modifiers[Powerup.PowerupType.PAUSE] > 0
	var mult = speed_mult
	if slowed: mult *= SLOW_AMOUNT
	
	if !slowed && velocity.length() > MIN_SPEED:
		velocity *= FRICTION
	
	position += velocity * delta * mult
	rotation += rotation_speed * delta * mult

func hit(strength: float, use_particles: bool = true) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_ROCK)
	
	if use_particles:
		sprite.hide()
		flash_sprite.show()
		
		hitflash.stop()
		hitflash.start()
		
		var new_particles = ParticleManager.get_particles(ParticleManager.ParticleType.ROCK_HIT)
		new_particles.global_position = global_position
		get_tree().current_scene.add_child(new_particles)
		new_particles.emitting = true
	
	hits -= (strength  + 0.01) # don't ask
	
	hit_bar.visible = strength > 0 or hit_bar.visible
	hit_bar.material.set_shader_parameter("progress", hits / data.hits[level])
	
	if hits > data.hits[level] and hits < data.hits[level] * 1.5:
		fortified.visible = true
		hit_bar.color = FORTIFIED
		fortified.position = -Vector2(4, 4) - Vector2(0, collision_shape.shape.size.y)
	elif fortified.visible:
		fortified.visible = false
		hit_bar.color = LIGHTER_HITS if lighten_hits else DEFAULT
	
	if hits <= 0.2:
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
