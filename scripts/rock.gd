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

var particles: Dictionary = {
	"hit": preload("res://scenes/rock_hit.tscn")
}

var asteroids: Array = [
	preload("res://assets/asteroids/asteroid_1.png"),
	preload("res://assets/asteroids/asteroid_2.png"),
	preload("res://assets/asteroids/asteroid_3.png"),
	preload("res://assets/asteroids/asteroid_4.png")
]

var hits: float
var pieces: int
var minerals: int
var level: int

func _ready() -> void:
	sprite.texture = asteroids[level - 1]
	base_scale = sprite.scale
	
	linear_velocity = velocity
	angular_velocity = rotation_speed
	
	sprite.material = sprite.material.duplicate()
	
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
		break_rock()

func break_rock() -> void:
	manager.break_rock(self)
	hitflash.stop()
	queue_free()

func set_level(new_level: int) -> void:
	level = new_level
	hits = level * 1.5
	pieces = floor(level / 2.0)
	minerals = floor(pow(level, 1.2))

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		hit(0.5)
