extends Node2D
class_name BulletSpawner

@onready var asteroids: Node2D = $"../AsteroidSpawner/Asteroids"

const BULLET = preload("uid://8wr24u7nbwu4")

var homing_bullets: Array[Bullet]

func spawn_bullet(pos: Vector2, dir: float) -> Bullet:
	var b = BULLET.instantiate()
	b.position = pos
	b.rotation = dir
	call_deferred("add_child", b)
	return b

func _process(delta: float) -> void:
	if homing_bullets.size() == 0: 
		return
	
	var a = asteroids.get_children()
	for bullet in homing_bullets:
		var closest = null
		var closest_distance = INF
		for asteroid in a:
			if bullet.global_position.distance_squared_to(asteroid.global_position) < closest_distance:
				closest = asteroid
				closest_distance = bullet.global_position.distance_squared_to(asteroid.global_position)
		
		if closest != null:
			bullet.global_position = bullet.global_position.move_toward(closest.global_position, 100. * delta)

func spawn_bullet_from_bullet(b: Bullet, pos: Vector2, dir: float, homing: bool = false) -> void:
	b.position = pos
	b.rotation = dir
	call_deferred("add_child", b)
	if homing: 
		homing_bullets.append(b)
		b.tree_exited.connect(func (): homing_bullets.erase(b))

func spawn_shards(asteroid: Asteroid) -> void:
	var amount = StatManager.get_stat("shard_amount").value
	var segment = 2 * PI / amount
	
	for i in range(amount):
		var b = spawn_bullet(asteroid.position, i * segment)
		b.pierce = StatManager.get_stat("shard_pierce").value
