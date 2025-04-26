extends Node
class_name AsteroidManager

var player := GameManager.player
var scenes: Dictionary[String, PackedScene] = {
	"rock": preload("res://scenes/mission/rock/rock.tscn"),
	"mineral": preload("res://scenes/mission/mineral/mineral.tscn")
}
@onready var parents: Dictionary[String, Node] = {
	"rock": $Rocks,
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
	spawn_new_rock()
	
	timers.get("spawn").wait_time = spawn.interval
	timers.get("spawn").timeout.connect(spawn_new_rock)
	
	timers.get("duration").wait_time = player.get_stat("fuel_capacity").value
	timers.get("duration").timeout.connect(mission_ended)
	
	for _name in timers:
		add_child(timers.get(_name))
		timers.get(_name).start()

func mission_ended() -> void:
	GameManager.state_changed.emit(GameManager.State.UPGRADES)
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

func spawn_new_rock() -> void:
	var edge = random_edge(50)
	var level = CustomMath.from_dist(randf(), spawn.mean, spawn.sd)
	_recalculate_spawn()
	
	spawn_rock(edge.position, edge.velocity * 500, level)

func spawn_rock(position: Vector2, velocity: Vector2, level: int) -> Rock:
	var new_rock = scenes.get("rock").instantiate()
	
	new_rock.set_level(level)
	new_rock.position = position
	new_rock.velocity = velocity
	new_rock.manager = self
	
	parents.get("rock").add_child(new_rock)
	
	return new_rock

func break_rock(rock: Rock) -> void:
	for i in rock.minerals:
		spawn_mineral(rock.position, CustomMath.random_vector(500))
	
	if rock.level == 1: return 
	
	for i in max(2, rock.pieces):
		var new_rock = spawn_rock(rock.position, CustomMath.random_vector(500), max(1, rock.level - 1))
		boundary.lock_in(new_rock)

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
