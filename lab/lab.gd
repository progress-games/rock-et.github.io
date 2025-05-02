extends Node2D

var target: float = 320
const SPEED := 10

func _ready() -> void:
	GameManager.state_changed.connect(_state_changed)
	
func _state_changed(state: GameManager.State) -> void:
	match state:
		GameManager.State.LAB:
			target = 0
		_:
			target = 320

func _process(delta: float) -> void:
	position.x += (target - position.x) * delta * SPEED
