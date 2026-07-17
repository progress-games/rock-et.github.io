extends Area2D
class_name Bullet

@export var speed = 180
@export var direction = 0
@export var pierce = 1

@export var hit_data: HitData

func _process(delta: float) -> void:
	position += Vector2(
		cos(rotation) * speed * delta,
		sin(rotation) * speed * delta
	)

func _on_body_entered(body: Node2D) -> void:
	if body.has_meta("asteroid"):
		GameManager.asteroid_hit.emit(body, hit_data)
		pierce -= 1
	if pierce <= 0: queue_free()
