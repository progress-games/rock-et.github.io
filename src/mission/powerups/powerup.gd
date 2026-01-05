extends Area2D
class_name Powerup

const SIN_AMP := 50
const SIN_PER := 5

enum PowerupType {
	SPEED_BOOST,
	FUEL_BOOST,
	MORE_MINERALS,
	DAMAGE_BOOST,
	#PAUSE,
	#AUTOCLICK,
	#AIM_ASSIST,
	#EXPLOSION
}

var velocity: Vector2
var powerup_type: PowerupType = PowerupType.FUEL_BOOST
var x := 0.0

func _ready() -> void:
	if powerup_type in [PowerupType.FUEL_BOOST, PowerupType.DAMAGE_BOOST]:
		$PowerupType.material = null
	
	$PowerupType.texture = GameManager.powerup_data[powerup_type].small

func _process(delta: float) -> void:
	x += delta
	velocity.y = sin(x * SIN_PER) * SIN_AMP
	position += velocity * delta
