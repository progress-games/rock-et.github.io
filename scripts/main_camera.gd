extends Camera2D

var target: Vector2
@onready var minerals = $Minerals
@onready var mineral = $Mineral
var count_mineral = preload("res://scenes/ui/count_mineral.tscn")

const SPEED := 3

func _ready() -> void:
	GameManager.state_changed.connect(update_facing)
	GameManager.collect_mineral.connect(_collect_mineral)
	update_facing(GameManager.state)
	
func update_facing(new_facing: GameManager.State) -> void:
	target = GameManager.LOCATIONS.get(new_facing)

func _process(delta: float) -> void:
	position += (target - position) * delta * SPEED
	
	if GameManager.state == GameManager.State.MISSION:
		target.y -= delta * GameManager.player.get_stat("thruster_speed").value

func _collect_mineral(_mineral: GameManager.Mineral, _position: Vector2, _rotation: float) -> void:
	var new_mineral = count_mineral.instantiate()
	new_mineral.global_position = _position
	new_mineral.texture = GameManager.MINERALS.get(_mineral)
	new_mineral.target = mineral.global_position
	new_mineral.rotation = _rotation
	minerals.add_child(new_mineral)
