extends Area2D

const SCREEN_CENTRE: int = 44
const FLY_UP_DUR := 1.5
const FLY_UP_DELAY := 0
const HP_BAR_WIDTH := 38

const ASTEROID_FALL_DUR = .6

const CLICK_BOX = preload("uid://by200eutp0c4c")

"""
when this is hit by a rock, take damage.

"""
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var ship: Sprite2D = $Ship
@onready var remaining_hp: ColorRect = $HP/Remaining
@onready var mission: Node2D = $".."
@onready var bullet_spawner: BulletSpawner = $"../BulletSpawner"

var hp: float
var max_hp: float

# asteroids can only be frozen once
var frozen_asteroids: Dictionary[int, bool]

signal broken

func _ready() -> void:
	hide()
	collision_shape.disabled = true
	
	if GameManager.planet != Enums.Planet.VULCAN: queue_free()
	
	GameManager.added_ship_hp.connect(
		func (a):
			hp = min(max_hp, hp + a)
	)
	
	hp = StatManager.get_stat("ship_health").value
	max_hp = hp
	fly_up()

func fly_up() -> void:
	show()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(self, "position:y", SCREEN_CENTRE, FLY_UP_DUR)
	t.finished.connect(func (): collision_shape.disabled = false)

func _on_area_entered(area: Area2D) -> void:
	if area.has_meta("asteroid"):
		asteroid_hit(area)

func asteroid_hit(asteroid: Asteroid) -> void:
	if !apply_bounce_effects(asteroid):
		return
	
	spawn_falling_asteroid(asteroid)
	
	hp -= 1 * (1 - StatManager.get_stat("ship_armour").value) * (asteroid.level + 1)
	remaining_hp.size.x = (hp / max_hp) * HP_BAR_WIDTH
		
	if hp <= 0:
		broken.emit()

# returns if the function can continue with spawning a falling asteroid
func apply_bounce_effects(asteroid: Asteroid) -> bool:
	for effect in BounceEffectManager.unlocked_effects:
		match effect:
			BounceEffectManager.BounceEffect.LIGHTNING:
				apply_lightning(asteroid)
			BounceEffectManager.BounceEffect.FREEZE:
				if randf() <= BounceEffectManager.get_stat(effect, BounceEffectManager.StatType.CHANCE):
					apply_freeze(asteroid)
					return false
			BounceEffectManager.BounceEffect.REFLECT:
				if randf() <= BounceEffectManager.get_stat(effect, BounceEffectManager.StatType.CHANCE):
					reflect_asteroid(asteroid)
					return false
			
			BounceEffectManager.BounceEffect.EXPLOSION:
				if randf() <= BounceEffectManager.get_stat(effect, BounceEffectManager.StatType.CHANCE):
					create_explosion.bind(asteroid).call_deferred()
			BounceEffectManager.BounceEffect.FRAGS:
				if randf() <= BounceEffectManager.get_stat(effect, BounceEffectManager.StatType.CHANCE):
					bullet_spawner.spawn_frags(asteroid)
	
	return true

func apply_lightning(asteroid: Asteroid) -> void:
	mission._chain_lightning(
		asteroid, 
		BounceEffectManager.get_stat(BounceEffectManager.BounceEffect.LIGHTNING, BounceEffectManager.StatType.CHANCE),
		BounceEffectManager.get_stat(BounceEffectManager.BounceEffect.LIGHTNING, BounceEffectManager.StatType.DAMAGE)
	)

func apply_freeze(asteroid: Asteroid) -> void:
	if asteroid.get_instance_id() in frozen_asteroids:
		return
	
	var dur = BounceEffectManager.get_stat(BounceEffectManager.BounceEffect.FREEZE, BounceEffectManager.StatType.DURATION)
	
	frozen_asteroids.set(asteroid.get_instance_id(), true)
	
	asteroid.set_frozen(dur)
	
	var t = create_tween().bind_node(asteroid)
	t.tween_interval(dur)
	t.finished.connect(asteroid_hit.bind(asteroid))

func reflect_asteroid(asteroid: Asteroid) -> void:
	if abs(asteroid.velocity.x) > abs(asteroid.velocity.y):
		asteroid.velocity.x = -asteroid.velocity.x
	else:
		asteroid.velocity.y = -asteroid.velocity.y
	
	asteroid.velocity *= 5

func create_explosion(asteroid: Asteroid) -> void:
	var new = CLICK_BOX.instantiate()
	new.click_effect = ClickEffectManager.ClickType.EXPLOSION
	get_parent().add_child(new)
	new.global_position = asteroid.global_position
	new.lighten_borders = false
	
	new.damage_override = BounceEffectManager.get_stat(
		BounceEffectManager.BounceEffect.EXPLOSION, 
		BounceEffectManager.StatType.DAMAGE)
	new.size_override = BounceEffectManager.get_stat(
		BounceEffectManager.BounceEffect.EXPLOSION, 
		BounceEffectManager.StatType.EXPLOSION_SIZE)

func spawn_falling_asteroid(asteroid: Asteroid) -> void:
	if !is_instance_valid(asteroid):
		return
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HIT_SHIP)
	
	var new := Sprite2D.new()
	new.modulate = Color(1, 1, 1, 0.5)
	new.texture = asteroid.sprite.texture
	new.rotation = asteroid.rotation
	
	var dir = clamp(asteroid.global_position.x - collision_shape.global_position.x, -1, 1)
	
	ship.rotation_degrees += dir * 15
	var t = create_tween()
	t.tween_property(ship, "rotation", 0, 0.1)
	
	var x = create_tween()
	x.tween_property(new, "position:x", new.position.x + randi_range(90, 100) * dir, 1)
	x.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	var y = create_tween()
	y.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	y.tween_property(new, "position:y", new.position.y + 150, ASTEROID_FALL_DUR)
	
	add_child(new)
	new.global_position = asteroid.global_position
	
	asteroid.queue_free()
