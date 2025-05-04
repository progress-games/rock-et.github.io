extends RigidBody2D
class_name Rock

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

const MIN_SPEED = 50
const FRICTION = 0.9
var velocity := Vector2(0, 0)
var rotation_speed = randf_range(-3, 3)

var scale_tween: Tween
var base_scale: Vector2
var manager: AsteroidManager
var hitflash: Timer

@export var hitflash_dur: float
@export var particles: Dictionary[String, PackedScene]
@export var asteroids: Array[Texture2D]
@export var asteroid_sizes: Array[Vector2]

var hits: float
var pieces: PiecesData
var drops: Array[MineralDrop]
var level: int
var level_data: Array[LevelData]

func _ready() -> void:
	set_meta("asteroid", true)
	
	sprite.texture = asteroids[level - 1]
	base_scale = sprite.scale
	
	linear_velocity = velocity
	angular_velocity = rotation_speed
	
	sprite.material = sprite.material.duplicate()
	
	collision_shape.shape.size = asteroid_sizes[level - 1]
	
	hitflash = Timer.new()
	hitflash.wait_time = hitflash_dur
	hitflash.one_shot = true
	hitflash.timeout.connect(reset_hitflash)
	add_child(hitflash)
	reset_hitflash()

func reset_hitflash() -> void:
	sprite.material.set_shader_parameter("flash_value", 0)

func _physics_process(_delta: float) -> void:
	if linear_velocity.length() > MIN_SPEED:
		linear_velocity *= FRICTION

func hit(strength: float) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_ROCK)
	
	sprite.scale = base_scale
	scale_tween = create_tween()
	scale_tween.tween_property(sprite, "scale", sprite.scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(sprite, "scale", sprite.scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	sprite.material.set_shader_parameter("flash_value", 1)
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
	manager.break_asteroid(self)
	hitflash.stop()
	queue_free()

func set_level(new_level: int) -> void:
	level = min(level_data.size(), new_level)
	var data = level_data[level - 1]
	hits = data.hits
	pieces = data.pieces
	drops = data.drops
