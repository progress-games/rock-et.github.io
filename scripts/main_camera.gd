extends Camera2D

var target: Vector2

const SPEED := 3

func _ready() -> void:
	GameManager.connect("state_changed", Callable(self, "update_facing"))
	update_facing(GameManager.state)
	
func update_facing(new_facing: GameManager.State) -> void:
	target = GameManager.LOCATIONS.get(new_facing)

func _process(delta: float) -> void:
	position += (target - position) * delta * SPEED
	
	if GameManager.state == GameManager.State.MISSION:
		target.y -= delta * GameManager.player.get_stat("thruster_speed").value
