extends Node
class_name AsteroidManager

var player := GameManager.player
var scenes: Dictionary[String, PackedScene] = {
	"rock": preload("res://scenes/rock.tscn"),
	"mineral": preload("res://scenes/mineral.tscn")
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

func _ready() -> void:
	spawn_new_rock()
	
	timers.get("spawn").wait_time = player.get_stat("spawn_rate").value
	timers.get("spawn").timeout.connect(spawn_new_rock)
	
	timers.get("duration").wait_time = player.get_stat("duration").value
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
	var shape = boundary.get_node("CollisionShape2D").shape
	
	match edge: 
		1: 
			result.position = Vector2(0, 
				randf_range(indent, shape.size.y) - indent)
			result.velocity = Vector2(1, randf() - 0.5)
		2:
			result.position = Vector2(shape.size.x,
				randf_range(indent, shape.size.y) - indent)
			result.velocity = Vector2(-1, randf() - 0.5)
		3:
			result.position = Vector2(randf_range(indent, shape.size.x - indent), 
			0)
			result.velocity = Vector2(randf() - 0.5, 1)
		_:
			result.position = Vector2(randf_range(indent, shape.size.x - indent), 
				shape.size.y)
			result.velocity = Vector2(randf() - 0.5, -1)
	
	return result

func spawn_new_rock() -> void:
	var edge = random_edge(50)
	var dist = player.get_stat("rock_level").value
	var level = CustomMath.from_dist(randf(), dist.m, dist.s)
	
	spawn_rock(edge.position, edge.velocity * 1000, level)

func spawn_rock(position: Vector2, velocity: Vector2, level: int) -> void:
	var new_rock = scenes.get("rock").instantiate()
	
	new_rock.set_level(level)
	new_rock.position = position
	new_rock.velocity = velocity
	new_rock.manager = self
	
	parents.get("rock").add_child(new_rock)

func break_rock(rock: Rock) -> void:
	for i in rock.minerals:
		spawn_mineral(rock.position, CustomMath.random_vector(500))
	
	for i in rock.pieces:
		var dist = player.get_stat("rock_level").value
		var level = CustomMath.from_dist(randf(), dist.m, dist.s)
		
		spawn_rock(rock.position, CustomMath.random_vector(2000), level)

func spawn_mineral(position: Vector2, velocity: Vector2) -> void:
	var new_mineral = scenes.get('mineral').instantiate()
	new_mineral.position = position
	new_mineral.linear_velocity = velocity
	new_mineral.angular_velocity = randf_range(-30, 30)
	parents.get("mineral").add_child(new_mineral)
