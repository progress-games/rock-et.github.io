extends Area2D
class_name Bullet

# recalculates closest asteroid every N frames
const HOMING_UPDATE_FREQ := 5

@export var speed = 180
@export var direction = 0
@export var pierce = 1

var initial_range := 300.
var _range := 300.
var rotate_around: Node2D

var homing_strength: float = 0.
var homing_next_update: int

var bullet_bounces: int

@export var hit_data: HitData

var hit_asteroids: Dictionary[int, bool]

@onready var sprite_2d: Sprite2D = $Sprite2D

var tex

signal collided(asteroid: Asteroid)
signal dealt_damage(amount: float)

func _ready() -> void:
	if tex: sprite_2d.texture = tex
	initial_range = _range

func _process(delta: float) -> void:
	if rotate_around == null:
		position += Vector2(
			cos(rotation) * speed * delta,
			sin(rotation) * speed * delta
		)
		_range -= speed * delta
		if _range <= 0:
			queue_free()
	else:
		rotation += speed * delta
		global_position = rotate_around.global_position + Vector2(
			cos(rotation) * 50.,
			sin(rotation) * 50.
		)
	

func _on_area_entered(body: Node2D) -> void:
	if body.has_meta("asteroid"):
		GameManager.asteroid_hit.emit(body, hit_data)
		dealt_damage.emit(hit_data.damage_mult)
		collided.emit(body)
		hit_asteroids.set(body.get_instance_id(), true)
		if bullet_bounces > 0:
			bullet_bounces -= 1
			rotation = randf_range(-PI, PI)
		else:
			pierce -= 1
	if pierce <= 0: 
		queue_free()

func set_texture(t) -> void:
	tex = t
