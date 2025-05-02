extends Node2D

@export var listening_state: GameManager.State
@export var default_target: float
@export var triggered_target: float

var target: float
const SPEED := 10

func _ready() -> void:
	GameManager.state_changed.connect(_state_changed)
	target = default_target
	
func _state_changed(state: GameManager.State) -> void:
	match state:
		listening_state:
			target = triggered_target
		_:
			target = default_target

func _process(delta: float) -> void:
	position.x += (target - position.x) * delta * SPEED
