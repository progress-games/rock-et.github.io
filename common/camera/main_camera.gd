extends Camera2D


var target: Vector2
@onready var minerals = $Minerals
# @onready var inventory = $Inventory
@onready var day_count := $Calendar/DayCount
var collect_mineral := preload("res://common/ui/collect_mineral/collect_mineral.tscn")

const SPEED := 3

func _ready() -> void:
	GameManager.state_changed.connect(update_facing)
	GameManager.collect_mineral.connect(_collect_mineral)
	update_facing(GameManager.state)
	
func update_facing(new_facing: Enums.State) -> void:
	target = GameManager.LOCATIONS.get(new_facing, GameManager.LOCATIONS[Enums.State.HOME])
	
	$Calendar.visible = new_facing == Enums.State.HOME
	day_count.text = str(GameManager.day)

func _process(delta: float) -> void:
	position += ((target + Vector2(160, 90)) - position) * delta * SPEED
	
	if $"../Background".position.y >= 1620:
		$GameComplete.visible = true
		$GameComplete/Days.text = $GameComplete/Days.text.replace("DAYS", GameManager.day)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		get_tree().paused = true

func _collect_mineral(_mineral: Mineral) -> void:
	var new_mineral = collect_mineral.instantiate()
	new_mineral.global_position = _mineral.position
	new_mineral.texture = _mineral.mineral_tex
	new_mineral.target = $Inventory.global_position
	new_mineral.rotation = _mineral.rotation
	new_mineral.value = _mineral.value
	new_mineral.mineral = _mineral.mineral
	minerals.add_child(new_mineral)
	
	GameManager.show_mineral.emit(_mineral.mineral)
