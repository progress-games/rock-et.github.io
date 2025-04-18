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

var hits: float
var pieces: int
var minerals: int
var level: int

func _ready() -> void:
	var level_scale = (1 + level / 10.0)
	base_scale = sprite.scale * level_scale
	sprite.scale = base_scale
	collision_shape.scale *= level_scale
	linear_velocity = velocity
	angular_velocity = rotation_speed
	
func _physics_process(delta: float) -> void:
	if linear_velocity.length() > MIN_SPEED:
		linear_velocity *= FRICTION

func hit(strength: float) -> void:
	sprite.scale = base_scale
	scale_tween = create_tween()
	
	scale_tween.tween_property(sprite, "scale", sprite.scale * 0.8, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(sprite, "scale", sprite.scale, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	hits -= strength
	if hits <= 0:
		break_rock()

func break_rock() -> void:
	manager.break_rock(self)
	queue_free()

func set_level(new_level: int) -> void:
	level = new_level
	hits = level * 1.5
	pieces = floor(level / 2.0)
	minerals = floor(pow(level, 1.2))

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		hit(0.5)
