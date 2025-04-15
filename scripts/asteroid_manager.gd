extends Node
class_name AsteroidManager

var player := GameManager.player
var scenes: Dictionary[String, PackedScene] = {
	"rock": preload("res://scenes/rock.tscn"),
	"mineral": preload("res://scenes/mineral.tscn")
}
var parents: Dictionary[String, PackedScene]
var timers: Dictionary[String, Timer] = {
	"spawn": Timer.new(),
	"duration": Timer.new()
}

# factory
static func new_manager(rock_parent: Node, mineral_parent: Node) -> AsteroidManager:
	var manager = preload("res://scripts/asteroid_manager.gd")
	var new_manager = manager.instantiate() as AsteroidManager
	new_manager.parents = {
		"rock": rock_parent,
		"mineral": mineral_parent
	}
	return new_manager
	
func _ready() -> void:
	timers.get("spawn").wait_time = player.get_stat("spawn_rate").value
	# timers.get("spawn").timeout.connect(null)
	
	timers.get("duration").wait_time = player.get_stat("duration").value
	timers.get("duration").timeout.connect(mission_ended)
	
	for _name in timers:
		add_child(timers.get(_name))
		timers.get(_name).start()

func mission_ended() -> void:
	GameManager.state_changed.emit(GameManager.State.UPGRADES)
	queue_free()
