extends Node2D

const DEFAULT_STATE := Enums.State.HOME
const BASE_SPAWN := {
	"interval": 2.5,
	"mean": 1,
	"sd": 0.3
}

var player: Player
var location: Vector2
var state: Enums.State

@export var asteroid_spawns: Array[AsteroidData]
@export var level_data: Array[LevelData]

## the total distance the player must fly in order to complete the game
const DISTANCE: int = 1800 - 180

## the current day. the first day is 1
var day: int = 1

var click_multiplier: float = 1

var weights: Dictionary[Enums.Asteroid, float]

# inventory
signal show_mineral(mineral: Enums.Mineral)
signal set_inventory(state: Enums.InventoryState, faded: bool, position: Vector2)
signal clear_inventory()
signal show_inventory()
signal hide_inventory()

# mission
signal boost(amount: float)
signal asteroid_broke()

#mouse
signal set_mouse_state(state: Enums.MouseState)
signal mouse_clicked(hit: Node)
signal finished_holding()
signal hide_discovery()

# state
signal state_changed(state: Enums.State)
signal day_changed(day: int)

# mineral
signal add_mineral(mineral: Enums.Mineral, amount: float)
signal collect_mineral(mineral: Mineral, position: Vector2)

# pause/play
signal pause()
signal play()

const LOCATIONS = {
	Enums.State.HOME: Vector2(0, 0),
	Enums.State.MISSION: Vector2(0, -180),
}

@export var mineral_data: Dictionary[Enums.Mineral, MineralData]

func _ready() -> void:
	player = Player.new()
	
	state_changed.connect(_state_changed)
	day_changed.connect(func (d): day = d)
	call_deferred("_emit_initial_state")
	
	for mineral in Enums.Mineral.values():
		if mineral_data.get(mineral) == null:
			push_error("Mineral: " + Enums.Mineral.find_key(mineral) + " has no data!")
	
	finished_holding.connect(play.emit)

func _emit_initial_state() -> void:
	state_changed.emit(DEFAULT_STATE)
	day_changed.emit(day)

func _state_changed(new: Enums.State) -> void:
	if state == Enums.State.MISSION:
		weights = {}
		day += 1
		day_changed.emit(day)
	
	state = new
	location = LOCATIONS.get(state, Vector2(160, 1170))

func get_stat(stat_name: String) -> Stat:
	return player.get_stat(stat_name)

func get_item_stat(item_name: String, stat_name: String, default = 1) -> Variant:
	return default if !player.has_equipped(item_name) else player.equipped_items[item_name].get_value(stat_name)

func can_afford(amount: float, mineral: Enums.Mineral) -> bool:
	return player.can_afford(amount, mineral)
