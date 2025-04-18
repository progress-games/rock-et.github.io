extends Camera2D

var target: Vector2

const SPEED := 10
const LOCATIONS = {
	GameManager.State.UPGRADES: Vector2(320, 541),
	GameManager.State.MISSION: Vector2(320, 183)
}

func _ready() -> void:
	GameManager.connect("state_changed", Callable(self, "update_facing"))
	update_facing(GameManager.state)
	
func update_facing(new_facing: GameManager.State) -> void:
	target = LOCATIONS.get(new_facing)

func _process(delta: float) -> void:
	position += (target - position) * delta * SPEED
