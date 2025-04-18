extends Node

const DEFAULT_STATE := State.UPGRADES

var player: Player
var state: State

signal state_changed(state: State)
signal add_point(amount: int)

enum State {
	UPGRADES,
	MISSION
}

func _ready() -> void:
	player = Player.new()
	state_changed.connect(func(_state): state = _state)
	call_deferred("_emit_initial_state")

func _emit_initial_state() -> void:
	state_changed.emit(DEFAULT_STATE)
