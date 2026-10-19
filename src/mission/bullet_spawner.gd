extends Node2D
class_name BulletSpawner

const TEPHRA_AMOUNT = 8
const TEPHRA_DAMAGE = 3.

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
		if bullet.homing_next_update > 0 || bullet.rotate_around != null:
			bullet.homing_next_update -= 1
			continue
		
		bullet.homing_next_update = bullet.HOMING_UPDATE_FREQ
		var closest = null
		var closest_distance = INF
		for asteroid in a:
			if bullet.hit_asteroids.has(asteroid.get_instance_id()):
				continue
			if bullet.global_position.distance_squared_to(asteroid.global_position) < closest_distance:
				closest = asteroid
				closest_distance = bullet.global_position.distance_squared_to(asteroid.global_position)
		
		if closest != null:
			bullet.rotation = bullet.global_position.angle_to_point(closest.global_position)
			bullet.global_position = bullet.global_position.move_toward(
				closest.global_position, bullet.homing_strength * delta)

func spawn_bullet_from_bullet(b: Bullet, pos: Vector2, dir: float, homing: float = 0.) -> void:
	b.position = pos
	b.rotation = dir
	call_deferred("add_child", b)
	if homing > 0.: 
		b.homing_strength = homing
		homing_bullets.append(b)
		b.tree_exited.connect(func (): homing_bullets.erase(b))

func spawn_shards(asteroid: Asteroid) -> void:
	var amount = StatManager.get_stat("shard_amount").value
	var segment = 2 * PI / amount
	
	for i in range(amount):
		var b = spawn_bullet(asteroid.position, i * segment)
		b.pierce = StatManager.get_stat("shard_pierce").value

func spawn_tephra(asteroid: Asteroid) -> void:
	var segment = 2 * PI / TEPHRA_AMOUNT
	
	for i in range(TEPHRA_AMOUNT):
		var b = spawn_bullet(asteroid.position, i * segment)
		b.hit_data.burn_damage = 0.5

func spawn_frags(asteroid: Asteroid) -> void:
	var amount = BounceEffectManager.get_stat(
		BounceEffectManager.BounceEffect.FRAGS,
		BounceEffectManager.StatType.FRAG_AMOUNT)
	var segment = 2 * PI / amount
	
	for i in range(amount):
		var b = spawn_bullet(asteroid.position, i * segment)
		b.hit_data.damage_mult = BounceEffectManager.get_stat(
			BounceEffectManager.BounceEffect.FRAGS,
			BounceEffectManager.StatType.DAMAGE)
		
		# yea...
		if BounceEffectManager.BounceEffect.BURN in BounceEffectManager.unlocked_effects and\
				randf() <= BounceEffectManager.get_stat(BounceEffectManager.BounceEffect.BURN,
				BounceEffectManager.StatType.CHANCE):
			
			b.hit_data.burn_damage = BounceEffectManager.get_stat(BounceEffectManager.BounceEffect.BURN,
				BounceEffectManager.StatType.DAMAGE)
