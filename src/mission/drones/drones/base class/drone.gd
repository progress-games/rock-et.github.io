extends Node2D
class_name Drone

"""
when ready to shoot, emit a signal with BulletData
the parent drone manager reads that and creates a bullet
could be a child of asteroid manager?

drone types:
	sniper: targets the highest hp asteroid with big damage and big pierce
	gunner: all-rounder, nearest asteroid
	lmg: nearest asteroid, high rate of fire
	grenade launcher: shoots grenades at the nearest clump
	flame thrower: 
		

gunner: dmg, fire rate, ammo
lmg: dmg, fire rate, ammo, spread
sniper: 

drone calls shoot with a bullet
the drone manager listens for this signal and when a drone shoots,
	instantiates the given bullet with a direction and position
"""
const BULLET = preload("uid://8wr24u7nbwu4")
const PROGRESS_BAR_SIZE = 9
const SHOT_POINTS: Dictionary[DroneEnums.DroneType, Vector2] = {
	DroneEnums.DroneType.GUNNER: Vector2(2, 3),
	DroneEnums.DroneType.SHOTGUNNER: Vector2(2, 3),
	DroneEnums.DroneType.SNIPER: Vector2(2, 2),
	DroneEnums.DroneType.SPRAYER: Vector2(2, 4),
	DroneEnums.DroneType.FLAMETHROWER: Vector2(6, 2),
	DroneEnums.DroneType.LAUNCHER: Vector2(7, 4),
	DroneEnums.DroneType.PRICKER: Vector2(3, 1),
	DroneEnums.DroneType.LASER: Vector2(6, 3),
	DroneEnums.DroneType.FLAILER: Vector2(3, 1)
}

var drone_stats: DroneStats
var drone_type: DroneEnums.DroneType
var bullet_sprite: Texture2D
var reload_timer: float = 0.
var current_ammo: int = 0

# updated by parent after requesting
var closest_asteroid: Asteroid

# current direction the drone is facing
var current_angle: float

@onready var shot_point: Node2D = $ShotPoint
@onready var ammo_progress: ColorRect = $Ammo/Progress
@onready var reload_progress: ColorRect = $Reload/Progress
@onready var range_circle: ColorRect = $Range
@onready var drone: Sprite2D = $Drone

# stats
var fire_rate: float
var ammo_capacity: int
var damage: float
var spread: float
var pierce: int
var bullet_speed: float
var bullet_speed_variance: float
var _range: float
var ammo_per_crate: int

@warning_ignore("unused_signal")
signal shot(bullet: Bullet)

@warning_ignore("unused_signal")
signal request_closest_asteroid

@warning_ignore("unused_signal")
signal used_ammo

func _ready() -> void:
	range_circle.material = range_circle.material.duplicate()
	range_circle.size = Vector2(_range, _range)
	range_circle.position = - range_circle.size / 2
	range_circle.material.set_shader_parameter("dash_color", 
		DroneManager.drone_colours.get(drone_type).colour_1)
	var c = DroneManager.drone_colours.get(drone_type).colour_2 as Color
	c.a -= 0.6
	range_circle.material.set_shader_parameter("fill_color", c)
	range_circle.hide()
	
	drone.texture = DroneManager.get_drone_sprite(drone_type)
	shot_point.position = SHOT_POINTS.get(drone_type)

func open_range() -> void:
	range_circle.show()
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(range_circle, "size", Vector2(_range, _range), 0.2)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(range_circle, "position", -Vector2(_range, _range) / 2., 0.2)

func close_range() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(range_circle, "size", Vector2.ZERO, 0.1)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t2.tween_property(range_circle, "position", Vector2.ZERO, 0.1)
	t.finished.connect(range_circle.hide)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("drone_ranges"):
		open_range()
	elif Input.is_action_just_released("drone_ranges"):
		close_range()
	
	
	if current_ammo > 0:
		reload_timer = max(0, reload_timer - delta * fire_rate)
		reload_progress.size.y = (1 - reload_timer) * PROGRESS_BAR_SIZE
		if reload_timer <= 0:
			shoot()
			update_ammo_display()

func update_ammo_display() -> void:
	ammo_progress.size.y = float(current_ammo) / ammo_capacity * PROGRESS_BAR_SIZE

func add_ammo() -> void:
	reload_timer = 1
	current_ammo = min(ammo_capacity, current_ammo + ammo_per_crate)
	update_ammo_display()

func get_angle() -> float:
	var angle = global_position.angle_to_point(closest_asteroid.global_position)
	angle += randf_range(-deg_to_rad(spread), deg_to_rad(spread))
	return angle

func set_angle() -> void:
	update_angle(get_angle())

func update_angle(angle: float) -> void:
	drone.flip_h =  angle < - PI / 2. || angle > PI / 2.
	drone.rotation = angle + (PI if drone.flip_h else 0.)
	current_angle = angle

func shoot() -> void:
	request_closest_asteroid.emit()
	if closest_asteroid == null: return
	
	reload_timer = 1
	set_angle()
	
	var t = create_tween()
	t.tween_property(drone, "scale", Vector2.ONE * 2.5, 0.1)
	t.tween_property(drone, "scale", Vector2.ONE * 0.8, 0.05)
	t.tween_property(drone, "scale", Vector2.ONE, 0.02)

func create_bullet() -> Bullet:
	var new_bullet = BULLET.instantiate() as Bullet
	new_bullet.tex = bullet_sprite
	new_bullet.pierce = pierce
	new_bullet.speed = bullet_speed
	new_bullet.hit_data.damage_mult = damage
	new_bullet.speed += randf_range(-bullet_speed_variance, bullet_speed_variance)
	new_bullet._range = _range
	
	return new_bullet

func set_stats(new_stats: DroneStats) -> void:
	drone_stats = new_stats
	drone_type = drone_stats.drone_type
	
	fire_rate = drone_stats.get_stat(DroneEnums.StatType.FIRE_RATE)
	ammo_capacity = int(ceil(drone_stats.get_stat(DroneEnums.StatType.AMMO)))
	damage = drone_stats.get_stat(DroneEnums.StatType.DAMAGE)
	spread = drone_stats.get_stat(DroneEnums.StatType.SPREAD)
	pierce = int(ceil(drone_stats.get_stat(DroneEnums.StatType.PIERCE)))
	bullet_speed = drone_stats.get_stat(DroneEnums.StatType.BULLET_SPEED)
	bullet_speed_variance = drone_stats.get_stat(DroneEnums.StatType.SPEED_VARIANCE)
	_range = drone_stats.get_stat(DroneEnums.StatType.RANGE)
	ammo_per_crate = int(ceil(drone_stats.get_stat(DroneEnums.StatType.AMMO_PER_CRATE)))
	
	current_ammo = ammo_capacity
	
	bullet_sprite = DroneManager.get_bullet_sprite(drone_type)
	
	reload_timer = 1
