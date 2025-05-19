extends Camera2D

var target: Vector2
@onready var minerals = $Minerals
@onready var inventory = $Inventory
var collect_mineral = preload("res://common/ui/collect_mineral/collect_mineral.tscn")

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

func _collect_mineral(_mineral: Mineral) -> void:
	var new_mineral = collect_mineral.instantiate()
	new_mineral.global_position = _mineral.position
	new_mineral.texture = _mineral.mineral_data.get("drop_" + str(_mineral.value))
	new_mineral.target = inventory.global_position
	new_mineral.rotation = _mineral.rotation
	new_mineral.value = _mineral.value
	new_mineral.mineral = _mineral.mineral
	minerals.add_child(new_mineral)
	
	inventory.show_mineral(_mineral.mineral)
