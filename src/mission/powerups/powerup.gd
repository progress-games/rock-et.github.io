extends Area2D
class_name Powerup

const SIN_AMP := 50
const SIN_PER := 5
const SPEED := 2
const SUPER_POWERUP := preload("res://mission/powerups/super_powerup.png")

enum PowerupType {
	SPEED_BOOST,
	MORE_MINERALS,
	DAMAGE_BOOST,
	#PAUSE,
	#AUTOCLICK,
	#AIM_ASSIST,
	#EXPLOSION
}

var super_powerup: bool

var velocity: Vector2
var powerup_type: PowerupType = PowerupType.SPEED_BOOST
var x := 0.0

func _ready() -> void:
	if powerup_type == PowerupType.DAMAGE_BOOST:
		$PowerupType.material = null
	
	if super_powerup: $Powerup.texture = SUPER_POWERUP
	
	$PowerupType.texture = GameManager.powerup_data[powerup_type].small

func _process(delta: float) -> void:
	x += delta * SPEED
	velocity.y = sin(x * SIN_PER) * SIN_AMP
	position += velocity * delta
