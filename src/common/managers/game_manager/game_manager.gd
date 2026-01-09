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

@export_group("Mission")
@export var asteroid_spawns: Array[AsteroidData]
@export var level_data: Array[LevelData]
@export var mineral_data: Dictionary[Enums.Mineral, MineralData]
@export var powerup_data: Dictionary[Powerup.PowerupType, PowerupData]

@export_group("Exchange Rates")
@export var exchange_rates:Dictionary[Enums.Mineral, ExchangeRate]

@export_group("Preload")
@export var particles: Dictionary[String, PackedScene]

## the total distance the player must fly to reach the next planet
const DISTANCES: Dictionary[Enums.Planet, int] = {
	Enums.Planet.DYRT: 2160 - 180,
	Enums.Planet.KRUOS: 1000
}

## the current day. the first day is 1
var day: int = 1

## the current planet
var planet: Enums.Planet = Enums.Planet.DYRT

## the target distance for the current planet
var planet_distance: int

var remove_preload_timer: Timer

var click_multiplier: float = 1

var weights: Dictionary[Enums.Asteroid, float]

## if the game is paused
var paused: bool = false
var endless := false

# inventory
@warning_ignore("unused_signal")
signal show_mineral(mineral: Enums.Mineral)
@warning_ignore("unused_signal")
signal set_inventory(state: Enums.InventoryState, faded: bool, position: Vector2)
@warning_ignore("unused_signal")
signal clear_inventory()
@warning_ignore("unused_signal")
signal show_inventory()
@warning_ignore("unused_signal")
signal hide_inventory()

# mission
@warning_ignore("unused_signal")
signal boost(amount: float)
@warning_ignore("unused_signal")
signal asteroid_broke()
@warning_ignore("unused_signal")
signal time_added()

#mouse
@warning_ignore("unused_signal")
signal set_mouse_state(state: Enums.MouseState)
@warning_ignore("unused_signal")
signal asteroid_hit(asteroid: Asteroid)
@warning_ignore("unused_signal")
signal powerup_hit(powerup: Powerup)
signal finished_holding()
@warning_ignore("unused_signal")
signal hide_discovery()

# state
signal state_changed(state: Enums.State)
signal day_changed(day: int)
@warning_ignore("unused_signal")
signal get_managed_state(state: Enums.State)
signal planet_changed(planet: Enums.Planet)

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

var state_data: Dictionary[Enums.State, Dictionary]

func _ready() -> void:
	player = Player.new()
	
	pause.connect(func (): paused = true)
	play.connect(func (): paused = false)
	
	state_changed.connect(_state_changed)
	day_changed.connect(func (d): 
		day = d
		for rate in exchange_rates.values(): rate.get_exchange(d)
	)
	planet_changed.connect(func (p: Enums.Planet): 
		planet = p
		planet_distance = DISTANCES[p])
	call_deferred("_emit_initial_state")
	
	for mineral in Enums.Mineral.values():
		if mineral_data.get(mineral) == null:
			push_error("Mineral: " + Enums.Mineral.find_key(mineral) + " has no data!")
	
	for rate in exchange_rates.values(): rate.set_up()
	finished_holding.connect(play.emit)

func _preload_particles() -> void:
	for n in particles.values():
		var p = n.instantiate()
		add_child(p)
		p.global_position = Vector2(-100, 0)
		p.set_meta("preloaded", true)
	
	remove_preload_timer = Timer.new()
	remove_preload_timer.wait_time = 0.2
	remove_preload_timer.one_shot = true
	remove_preload_timer.timeout.connect(_remove_preloaded)
	add_child(remove_preload_timer)
	remove_preload_timer.start()

func _remove_preloaded() -> void:
	for n in get_children():
		if n.has_meta("preloaded"):
			n.queue_free()

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

func get_item_stat(item_name: String, stat_name: String, default = 1) -> Variant:
	return default if !player.has_equipped(item_name) else player.equipped_items[item_name].get_value(stat_name)

func can_afford(amount: float, mineral: Enums.Mineral) -> bool:
	return player.can_afford(amount, mineral)
