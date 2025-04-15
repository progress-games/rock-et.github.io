extends Node

const DEFAULT_STATE := State.UPGRADES

var player: Player
var state: State
signal state_changed(state: State)

enum State {
	UPGRADES,
	MISSION
}

func _ready() -> void:
	player = Player.new()
	state_changed.connect(func(_state): state = _state)
	emit_signal("state_changed", DEFAULT_STATE)
