extends Area2D
class_name Bullet

@export var speed = 180
@export var direction = 0
@export var pierce = 1

var _range := 300.

@export var hit_data: HitData

@onready var sprite_2d: Sprite2D = $Sprite2D

var tex

func _ready() -> void:
	if tex: sprite_2d.texture = tex

func _process(delta: float) -> void:
	position += Vector2(
		cos(rotation) * speed * delta,
		sin(rotation) * speed * delta
	)
	
	_range -= speed * delta
	if _range <= 0:
		queue_free()
	

func _on_area_entered(body: Node2D) -> void:
	if body.has_meta("asteroid"):
		GameManager.asteroid_hit.emit(body, hit_data)
		pierce -= 1
	if pierce <= 0: queue_free()

func set_texture(t) -> void:
	tex = t
