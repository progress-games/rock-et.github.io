extends Sprite2D

var home: Vector2
var target: Vector2
const SPEED := 3

func _ready() -> void:
	home = position
	GameManager.boost.connect(func (amount):
		target.y += GameManager.DISTANCE * amount
	)

func _process(delta: float) -> void:
	if GameManager.state == Enums.State.MISSION:
		target.y += delta * GameManager.player.get_stat("thruster_speed").value
	else:
		target = home
		
	position += (target - position) * delta * SPEED
