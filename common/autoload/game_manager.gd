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

## the current day
var day: int = 0

var click_multiplier: float = 1

var weights: Dictionary[Enums.Asteroid, float]

var day_stats: Dictionary[String, Variant] = {
	"minerals": {
		Enums.Mineral.AMETHYST: 0
	},
	"upgrades": [
		"fuel capacity"
	]
}

signal state_changed(state: Enums.State)
signal add_mineral(mineral: Enums.Mineral, amount: int)
signal collect_mineral(mineral: Mineral, position: Vector2)
signal show_mineral(mineral: Enums.Mineral)
signal hide_mineral(mineral: Enums.Mineral)
signal hide_discovery()
signal set_mouse_state(state: Enums.MouseState)
signal mouse_clicked(hit: Node)
signal finished_holding()
signal hide_inventory()
signal show_inventory()
signal asteroid_broke()
signal day_changed(day: int)
signal boost(amount: float)

signal pause()
signal play()

const LOCATIONS = {
	Enums.State.HOME: Vector2(0, 0),
	Enums.State.MISSION: Vector2(0, -180),
}

const MINERAL_TEXTURES = {
	Enums.Mineral.AMETHYST: preload("res://common/minerals/amethyst.png"),
	Enums.Mineral.TOPAZ: preload("res://common/minerals/topaz.png"),
	Enums.Mineral.KYANITE: preload("res://common/minerals/kyanite.png"),
	Enums.Mineral.OLIVINE: preload("res://common/minerals/olivine.png"),
	Enums.Mineral.CORUNDUM: preload("res://common/minerals/corundum.png")
}

const MINERAL_COLOURS = {
	Enums.Mineral.AMETHYST: {
		"primary": Color('905ea9'),
		"secondary": Color('45293f')
	},
	Enums.Mineral.TOPAZ: {
		"primary": Color('ea4f36'),
		"secondary": Color('6e2727')
	},
	Enums.Mineral.KYANITE: {
		"primary": Color('4d65b4'),
		"secondary": Color('323353')
	},
	Enums.Mineral.OLIVINE: {
		"primary": Color('a2a947'),
		"secondary": Color('4c3e24')
	},
	Enums.Mineral.CORUNDUM: {
		"primary": Color('fb6b1d'),
		"secondary": Color('ae2334')
	}
}

func _ready() -> void:
	day_stats = {"minerals": {}, "upgrades": []}
	player = Player.new()
	
	state_changed.connect(_state_changed)
	day_changed.connect(func (d): day = d)
	call_deferred("_emit_initial_state")
	
	player.stat_upgraded.connect(func (s: Stat): day_stats.upgrades.append(s.display_name))
	add_mineral.connect(func (m: Enums.Mineral, a: int): 
		if a > 0:
			day_stats.minerals.set(m, day_stats.minerals.get(m, 0) + a))
	finished_holding.connect(play.emit)

func _emit_initial_state() -> void:
	state_changed.emit(DEFAULT_STATE)
	day_changed.emit(day)

func _state_changed(new: Enums.State) -> void:
	if state == Enums.State.MISSION:
		weights = {}
		day += 1
		day_changed.emit(day)
		day_stats = {"minerals": {}, "upgrades": []}
	
	state = new
	location = LOCATIONS.get(state, Vector2(160, 1170))

func get_stat(stat_name: String) -> Stat:
	return player.get_stat(stat_name)
