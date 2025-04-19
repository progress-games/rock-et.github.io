extends Node

const DEFAULT_STATE := State.UPGRADES

var player: Player
var location: Vector2
var state: State

signal state_changed(state: State)
signal add_point(amount: int)

enum State {
	UPGRADES,
	MISSION
}

const LOCATIONS = {
	GameManager.State.UPGRADES: Vector2(160, 1170),
	GameManager.State.MISSION: Vector2(160, 1170 - 180)
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
