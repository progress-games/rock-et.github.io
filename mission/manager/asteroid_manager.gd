extends Node
class_name AsteroidManager

var player := GameManager.player
var scenes: Dictionary[String, PackedScene] = {
	"asteroid": preload("res://mission/asteroid/asteroid.tscn"),
	"mineral": preload("res://mission/mineral/mineral.tscn")
}
@onready var parents: Dictionary[String, Node] = {
	"asteroid": $Asteroids,
	"mineral": $Minerals
}
var timers: Dictionary[String, Timer] = {
	"spawn": Timer.new(),
	"duration": Timer.new()
}
@onready var boundary = $Boundary
@onready var fuel_left = $FuelLeft
var spawn = GameManager.BASE_SPAWN.duplicate()

func _ready() -> void:
	spawn_new_asteroid()
	
	timers.get("spawn").wait_time = spawn.interval
	timers.get("spawn").timeout.connect(spawn_new_asteroid)
	
	timers.get("duration").wait_time = player.get_stat("fuel_capacity").value
	timers.get("duration").timeout.connect(mission_ended)
	
	for _name in timers:
		add_child(timers.get(_name))
		timers.get(_name).start()

func mission_ended() -> void:
	GameManager.state_changed.emit(GameManager.State.HOME)
	queue_free()

func random_edge(indent: int = 50) -> Dictionary:
	var edge = randi_range(1, 4)
	var result = {
		"position": Vector2(0, 0),
		"velocity": Vector2(0, 0)
	}
	# extents is w/2, h/2
	var size = boundary.get_node("CollisionShape2D").shape.extents
	var pos = boundary.collision_shape.global_position
	
	match edge: 
		1: # North
			result.position = pos + Vector2(randf_range(-size.x + indent, size.x - indent), - size.y)
			result.velocity = Vector2(randf() - 0.5, 1)
		2: # East
			result.position = pos + Vector2(size.x, randf_range(-size.y + indent, size.y - indent))
			result.velocity = Vector2(-1, randf() - 0.5)
		3: # South
			result.position = pos + Vector2(randf_range(-size.x + indent, size.x - indent), size.y)
			result.velocity = Vector2(randf() - 0.5, -1)
		_: # West
			result.position = pos + Vector2(- size.x, randf_range(-size.y + indent, size.y - indent))
			result.velocity = Vector2(1, randf() - 0.5)
	
	return result

func spawn_new_asteroid() -> void:
	var edge = random_edge(50)
	var level = CustomMath.from_dist(randf(), spawn.mean, spawn.sd)
	_recalculate_spawn()
	
	spawn_asteroid(edge.position, edge.velocity * 500, level)

func spawn_asteroid(position: Vector2, velocity: Vector2, level: int) -> Rock:
	var new_asteroid = scenes.get("asteroid").instantiate()
	
	new_asteroid.set_level(level)
	new_asteroid.position = position
	new_asteroid.velocity = velocity
	new_asteroid.manager = self
	
	parents.get("asteroid").add_child(new_asteroid)
	
	return new_asteroid

func break_asteroid(asteroid: Rock) -> void:
	for i in asteroid.minerals:
		spawn_mineral(asteroid.position, CustomMath.random_vector(500))
	
	if asteroid.level == 1: return 
	
	for i in max(2, asteroid.pieces):
		var new_asteroid = spawn_asteroid(asteroid.position, CustomMath.random_vector(500), max(1, asteroid.level - 1))
		boundary.lock_in(new_asteroid)

func spawn_mineral(position: Vector2, velocity: Vector2) -> void:
	var new_mineral = scenes.get('mineral').instantiate()
	new_mineral.position = position
	new_mineral.linear_velocity = velocity
	new_mineral.angular_velocity = randf_range(-30, 30)
	parents.get("mineral").add_child(new_mineral)

func _recalculate_spawn() -> void:
	var distance = (abs(boundary.global_position.y) / 100) + 1
	spawn.interval = GameManager.BASE_SPAWN.interval - distance * 0.2
	spawn.mean = GameManager.BASE_SPAWN.mean + distance * 0.1
	spawn.sd = GameManager.BASE_SPAWN.sd + distance * 0.15
	
	timers.get("spawn").wait_time = spawn.interval
