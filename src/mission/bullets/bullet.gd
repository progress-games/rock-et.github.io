extends Area2D
class_name Bullet

@export var speed = 180
@export var direction = 0
@export var pierce = 1

var initial_range := 300.
var _range := 300.
var rotate_around: Node2D

@export var hit_data: HitData

@onready var sprite_2d: Sprite2D = $Sprite2D

var tex

signal collided(asteroid: Asteroid)

func _ready() -> void:
	if tex: sprite_2d.texture = tex
	initial_range = _range

func _process(delta: float) -> void:
	if rotate_around == null:
		position += Vector2(
			cos(rotation) * speed * delta,
			sin(rotation) * speed * delta
		)
	else:
		rotation += speed * delta
		global_position = rotate_around.global_position + Vector2(
			cos(rotation) * initial_range,
			sin(rotation) * initial_range
		)
		
	
	_range -= speed * delta
	if _range <= 0:
		queue_free()

func _on_area_entered(body: Node2D) -> void:
	if body.has_meta("asteroid"):
		GameManager.asteroid_hit.emit(body, hit_data)
		collided.emit(body)
		pierce -= 1
	if pierce <= 0: 
		queue_free()

func set_texture(t) -> void:
	tex = t
