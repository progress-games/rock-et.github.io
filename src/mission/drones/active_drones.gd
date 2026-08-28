extends Node2D

const DRONE_RECT := 16
const AMMO_FREQUENCY := 10
const SCREEN_CENTRE := Vector2(160, 90)

const DRONE_SCENE = preload("uid://bbubtjito320x")
const AMMO_BOX = preload("uid://b0f8x0wdjrtcy")

@export var drone_scripts: Dictionary[DroneEnums.DroneType, Script]

@onready var bullet_spawner: BulletSpawner = $"../BulletSpawner"
@onready var asteroids: Node2D = $"../AsteroidSpawner/Asteroids"
@onready var ammo: VBoxContainer = $Ammo
@onready var drones_pos: Area2D = $Drones

# this only exists so the area2d doesnt throw a warning
@onready var collision_shape_2d: CollisionShape2D = $Drones/CollisionShape2D

var drones: Array[Drone]

var ammo_timer: Timer

func _ready() -> void:
	if GameManager.planet != Enums.Planet.VULCAN: 
		queue_free() 
		return
	
	ammo_timer = Timer.new()
	ammo_timer.timeout.connect(spawn_ammo_box)
	add_child(ammo_timer)
	ammo_timer.start(AMMO_FREQUENCY)
	
	spawn_drones(DroneManager.equipped_drones)
	ammo.load_drones(drones)
	
	collision_shape_2d.queue_free()

func spawn_ammo_box() -> void:
	var new_box = AMMO_BOX.instantiate()
	var target_position = Vector2(
		[-1, 1].pick_random() * randi_range(30, 140), 
		randi_range(-70, 70))
	var initial_position = Vector2(
		cos(Vector2.ZERO.angle_to_point(target_position)) * 500,
		sin(Vector2.ZERO.angle_to_point(target_position)) * 500)
	
	add_child(new_box)
	new_box.opened.connect(func (): open_ammo_box(new_box))
	new_box.position = initial_position
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	t.tween_property(new_box, "position", target_position, 1)

func open_ammo_box(ammo_box: AmmoBox) -> void:
	ammo_box.queue_free()
	drones.map(func (x): x.add_ammo())
	ammo.add_ammo()

func spawn_drones(drone_positions: Array[DronePosition]) -> void:
	var rect = RectangleShape2D.new()
	rect.size.x = 16
	rect.size.y = 16
	
	for drone_pos in drone_positions:
		var drone_type = drone_pos.drone_stats.drone_type
		var new_drone = DRONE_SCENE.instantiate()
		new_drone.set_script(drone_scripts.get(drone_type))
		new_drone.set_stats(drone_pos.drone_stats)
		
		new_drone.position = Vector2(
			drone_pos.x * DRONE_RECT,
			drone_pos.y * DRONE_RECT
		)
		
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = rect
		collision_shape.position = new_drone.position
		drones_pos.add_child(collision_shape)
		
		drones.append(new_drone)
		drones_pos.add_child(new_drone)
		
		new_drone.shot.connect(func (b): spawn_bullet(new_drone, b))
		new_drone.request_closest_asteroid.connect(func (): update_closest(new_drone))

func _process(_delta: float) -> void:
	var m = get_global_mouse_position()
	drones_pos.global_position = lerp(drones_pos.global_position, m, .1)

func spawn_bullet(d: Drone, bullet: Bullet) -> void:
	var pos = drones_pos.position + d.position
	# if statement just checks if sprite is flipped or not
	pos += d.shot_point.position * (
		Vector2(-1, 1) if d.drone.flip_h else Vector2.ONE)
	
	bullet_spawner.spawn_bullet_from_bullet(
		bullet, 
		pos,
		d.current_angle
	)
	
	ammo.shot(d)

func update_closest(drone: Drone) -> void:
	drone.closest_asteroid = get_closest_asteroid(drone.global_position, drone._range)

func get_closest_asteroid(pos: Vector2, max_range: float) -> Asteroid:
	var closest_idx = 0
	var closest_distance = INF
	
	for i in asteroids.get_child_count():
		var asteroid = asteroids.get_child(i)
		var distance = pos.distance_squared_to(asteroid.global_position)
		if distance < closest_distance:
			closest_idx = i
			closest_distance = distance
	
	if closest_distance > pow(max_range, 2):
		return
	
	return asteroids.get_child(closest_idx)
