extends Node2D

const BULLET = preload("uid://8wr24u7nbwu4")

func spawn_bullet(pos: Vector2, dir: float) -> Bullet:
	var b = BULLET.instantiate()
	b.position = pos
	b.rotation = dir
	call_deferred("add_child", b)
	return b

func spawn_shards(asteroid: Asteroid) -> void:
	var amount = StatManager.get_stat("shard_amount").value
	var segment = 2 * PI / amount
	
	for i in range(amount):
		var b = spawn_bullet(asteroid.position, i * segment)
		b.pierce = StatManager.get_stat("shard_pierce").value
