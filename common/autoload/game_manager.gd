extends Node

const DEFAULT_STATE := State.HOME
const BASE_SPAWN := {
	"interval": 2.5,
	"mean": 1,
	"sd": 0.3
}

var player: Player
var location: Vector2
var state: State

## the total distance the player must fly in order to complete the game
var distance: int = 1260 - 180

## the current day
var day: int = 0

var weights: Dictionary[Asteroid, float]

signal state_changed(state: State)
signal add_mineral(mineral: Mineral, amount: int)
signal collect_mineral(mineral: Mineral, position: Vector2)

enum State {
	HOME,
	MISSION,
	GARAGE,
	LAB
}

enum Mineral {
	AMETHYST,
	TOPAZ
}

enum Asteroid {
	AMETHYST,
	TOPAZ
}

const LOCATIONS = {
	GameManager.State.HOME: Vector2(160, 1170),
	GameManager.State.MISSION: Vector2(160, 1170 - 180),
	GameManager.State.GARAGE: Vector2(160, 1170),
	GameManager.State.LAB: Vector2(160, 1170)
}

const MINERAL_TEXTURES = {
	GameManager.Mineral.AMETHYST: preload("res://common/minerals/amethyst.png"),
	GameManager.Mineral.TOPAZ: preload("res://common/minerals/topaz.png")
}

func _ready() -> void:
	player = Player.new()
	state_changed.connect(_state_changed)
	call_deferred("_emit_initial_state")

func _emit_initial_state() -> void:
	state_changed.emit(DEFAULT_STATE)

func _state_changed(new: State) -> void:
	if state == GameManager.State.MISSION:
		weights = {}
		day += 1
	
	state = new
	location = LOCATIONS.get(state)
