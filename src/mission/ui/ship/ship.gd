extends Area2D

const SCREEN_CENTRE: int = 44
const FLY_UP_DUR := 2
const FLY_UP_DELAY := 0
const HP_BAR_WIDTH := 38

const ASTEROID_FALL_DUR = .6

"""
when this is hit by a rock, take damage.

"""
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var ship: Sprite2D = $Ship
@onready var remaining_hp: ColorRect = $HP/Remaining

var hp := 50.

signal broken

func _ready() -> void:
	hide()
	collision_shape.disabled = true
	
	if GameManager.planet != Enums.Planet.VULCAN: queue_free()
	
	var t = Timer.new()
	t.timeout.connect(fly_up)
	add_child(t)
	t.start(FLY_UP_DELAY)

func fly_up() -> void:
	show()
	var t = create_tween()
	t.tween_property(self, "position:y", SCREEN_CENTRE, FLY_UP_DUR)
	t.finished.connect(func (): collision_shape.disabled = false)

func _on_area_entered(area: Area2D) -> void:
	if area.has_meta("asteroid"):
		spawn_falling_asteroid(area)
		hp -= 1
		remaining_hp.size.x = (hp / 50.) * HP_BAR_WIDTH
		
		if hp <= 0:
			broken.emit()

func spawn_falling_asteroid(asteroid: Asteroid) -> void:
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
