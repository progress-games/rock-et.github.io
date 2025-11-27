extends RigidBody2D
class_name Asteroid

const MIN_SPEED = 50
const FRICTION = 0.9
const TEXTURE_DIMENSIONS = 38
var velocity := Vector2(0, 0)
var rotation_speed = randf_range(-3, 3)

var scale_tween: Tween
var base_scale: Vector2
var hitflash: Timer

@export var hitflash_dur: float
@export var particles: Dictionary[String, PackedScene]

var hits: float
var level: int
var data: AsteroidData
var asteroid_type: Enums.Asteroid
var erraticness: float
var erratic_timer: Timer = Timer.new()

signal asteroid_broken(asteroid: Asteroid)

func _ready() -> void:
	set_meta("asteroid", true)
	
	_set_region()
	erraticness = GameManager.get_item_stat("target_practice", "erratic_movement")
	
	hits = data.hits[level]
	asteroid_type = data.asteroid_type
	
	base_scale = $Sprite2D.scale
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

func reset_hitflash() -> void:
	$Sprite2D.material.set_shader_parameter("flash_value", 0)

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > MIN_SPEED:
		linear_velocity *= FRICTION

func hit(strength: float) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_ROCK)
	
	$Sprite2D.scale = base_scale
	scale_tween = create_tween()
	scale_tween.tween_property($Sprite2D, "scale", $Sprite2D.scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property($Sprite2D, "scale", $Sprite2D.scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	$Sprite2D.material.set_shader_parameter("flash_value", 1)
	hitflash.stop()
	hitflash.start()
	
	var new_particles = particles.get("hit").instantiate()
	new_particles.global_position = global_position
	get_tree().current_scene.add_child(new_particles)
	new_particles.emitting = true
	
	new_particles.finished.connect(new_particles.queue_free)
	
	hits -= strength
	if hits <= 0:
		break_asteroid()

func break_asteroid() -> void:
	asteroid_broken.emit(self)
	hitflash.stop()
	queue_free()

func find_closest_asteroid(hit: Array = []) -> RigidBody2D:
	var asteroids = get_parent().get_children()
	var closest: RigidBody2D = null
	var closest_dist := INF
	
	for asteroid in asteroids:
		if asteroid == self:
			continue
		if not asteroid is RigidBody2D:
			continue
		if asteroid in hit:
			continue
		
		var dist = global_position.distance_squared_to(asteroid.global_position)
		if dist < closest_dist:
			closest = asteroid
			closest_dist = dist
			
	return closest

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
	$Sprite2D.texture = texture
	$Sprite2D.material = $Sprite2D.material.duplicate()
	$CollisionShape2D.shape.size = $Sprite2D.texture.get_image().get_used_rect().size
