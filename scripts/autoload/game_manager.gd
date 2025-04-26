extends Node

const DEFAULT_STATE := State.UPGRADES
const BASE_SPAWN := {
	"interval": 2.5,
	"mean": 1,
	"sd": 0.3
}

var player: Player
var location: Vector2
var state: State

signal state_changed(state: State)
signal add_mineral(mineral: Mineral, amount: int)
signal collect_mineral(mineral: Mineral, position: Vector2)

enum State {
	UPGRADES,
	MISSION,
	GARAGE
}

enum Mineral {
	AMETHYST,
	IRON,
	URANIUM,
}

const LOCATIONS = {
	GameManager.State.UPGRADES: Vector2(160, 1170),
	GameManager.State.MISSION: Vector2(160, 1170 - 180),
	GameManager.State.GARAGE: Vector2(160, 1170),
}

const MINERALS = {
	GameManager.Mineral.AMETHYST: preload("res://assets/minerals/amethyst.png")
}

func _ready() -> void:
	player = Player.new()
	state_changed.connect(_state_changed)
	call_deferred("_emit_initial_state")

func _emit_initial_state() -> void:
	state_changed.emit(DEFAULT_STATE)

func _state_changed(new: State) -> void:
	state = new
	location = LOCATIONS.get(state)
