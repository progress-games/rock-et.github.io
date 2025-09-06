extends Node2D

@export var listening_state: Enums.State
@export var default_target: Vector2
@export var triggered_target: Vector2

## must have visited this location first
@export var requirement: Enums.State = Enums.State.HOME

## changes to this state if requirement wasn't met
@export var redirect: Enums.State = Enums.State.HOME

var target: Vector2
const SPEED := 10

func _ready() -> void:
	GameManager.state_changed.connect(_state_changed)
	target = default_target
	
func _state_changed(state: Enums.State) -> void:
	match state:
		listening_state:
			if GameManager.player.has_discovered_state(requirement):
				target = triggered_target
			else:
				GameManager.state_changed.emit(redirect)
		_:
			target = default_target

func _process(delta: float) -> void:
	position += (target - position) * delta * SPEED
