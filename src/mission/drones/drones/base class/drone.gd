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
	DroneEnums.DroneType.FLAILER: Vector2(3, 1),
	DroneEnums.DroneType.HEATSEEKER: Vector2(6, 4)
}
const FREEZE_DUR = 1.5

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
@onready var drone: Sprite2D = $Drone

# stats
var fire_rate: float
var ammo_capacity: int
var damage: float
var spread: float
var pierce: int
var bullet_speed: float
var bullet_speed_variance: float
var ammo_per_crate: int
var ghost_ammo_chance: float

var double_shot_chance: float
var bullet_bounces: int

# alot of this stuff is passed to hit_data
var homing_strength: float
var bauxite_chance: float
var crit_chance: float
var lightning_chance: float = 0.
var freeze_chance: float = 0.

var damage_dealt: float = 0.

@warning_ignore("unused_signal")
signal shot(bullet: Bullet)

@warning_ignore("unused_signal")
signal request_closest_asteroid

@warning_ignore("unused_signal")
signal used_ammo

func _ready() -> void:
	drone.texture = DroneManager.get_drone_sprite(drone_type)
	shot_point.position = SHOT_POINTS.get(drone_type)

func _process(delta: float) -> void:
	if current_ammo > 0:
		reload_timer = max(0, reload_timer - delta * fire_rate)
		reload_progress.size.y = (1 - reload_timer) * PROGRESS_BAR_SIZE
		if reload_timer <= 0:
			try_to_shoot()
			update_ammo_display()

func update_ammo_display() -> void:
	ammo_progress.size.y = float(current_ammo) / ammo_capacity * PROGRESS_BAR_SIZE

func add_ammo() -> void:
	reload_timer = 1
	current_ammo = ammo_capacity
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
	pass

func consume_ammo() -> void:
	if randf() < ghost_ammo_chance:
		return
	
	current_ammo -= 1

func try_to_shoot() -> void:
	request_closest_asteroid.emit()
	if closest_asteroid == null: 
		return
	
	reload_timer = 1
	set_angle()
	
	var t = create_tween()
	t.tween_property(drone, "scale", Vector2.ONE * 2.5, 0.1)
	t.tween_property(drone, "scale", Vector2.ONE * 0.8, 0.05)
	t.tween_property(drone, "scale", Vector2.ONE, 0.02)
	
	shoot()
	
	if randf() < double_shot_chance:
		var double = Timer.new()
		double.timeout.connect(try_to_shoot)
		double.one_shot = true
		add_child(double)
		double.start(0.5)

func increase_dealt(a: float) -> void:
	damage_dealt += a

func create_bullet() -> Bullet:
	var new_bullet = BULLET.instantiate() as Bullet
	new_bullet.tex = bullet_sprite
	new_bullet.pierce = pierce
	new_bullet.speed = bullet_speed
	new_bullet.speed += randf_range(-bullet_speed_variance, bullet_speed_variance)
	new_bullet.bullet_bounces = bullet_bounces
	
	new_bullet.hit_data.damage_mult = damage
	new_bullet.hit_data.bauxite_chance = bauxite_chance
	new_bullet.hit_data.crit_chance = crit_chance
	new_bullet.hit_data.lightning_chance_increase = lightning_chance
	
	new_bullet.dealt_damage.connect(increase_dealt)
	
	if randf() < freeze_chance:
		new_bullet.hit_data.freeze_dur = FREEZE_DUR
	
	current_angle = get_angle()
	
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
	ammo_per_crate = int(ceil(drone_stats.get_stat(DroneEnums.StatType.AMMO_PER_CRATE)))
	
	homing_strength = drone_stats.get_stat(DroneEnums.StatType.HOMING_STRENGTH)
	bauxite_chance = drone_stats.get_stat(DroneEnums.StatType.BAUXITE_CHANCE)
	crit_chance = drone_stats.get_stat(DroneEnums.StatType.CRIT_CHANCE)
	
	current_ammo = ammo_capacity
	
	bullet_sprite = DroneManager.get_bullet_sprite(drone_type)
	
	reload_timer = 1
