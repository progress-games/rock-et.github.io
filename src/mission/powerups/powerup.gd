extends Area2D
class_name Powerup

const SIN_AMP := 50
const SIN_PER := 5
const SPEED := 2
const SUPER_POWERUP := preload("res://mission/powerups/super_powerup.png")

enum PowerupType {
	SPEED_BOOST, # temp boost
	DOUBLE_MINERALS, # next n minerals drop double
	DOUBLE_CLICK, # next n clicks are double clicks
	INSTA_BREAK, # next n rocks are instantly broken
	MORE_ROCKS, # next rock broken spawns n additional new rocks
	PAUSE, # all rocks are frozen for n seconds
	SIZE_UP, # target size up
	AUTOCLICK, # autoclicks your cursor every n seconds
	#aim_assist,
	#damage_boost
	#more_minerals
}

@onready var powerup: Sprite2D = $Powerup
@onready var powerup_type_sprite: Sprite2D = $PowerupType

var super_powerup: bool

var velocity: Vector2
var powerup_type: PowerupType = PowerupType.SPEED_BOOST
var x := 0.0

func _ready() -> void:
	#if powerup_type == PowerupType.DOUBLE_CLICK:
		#powerup_type_sprite.material = null
	
	if super_powerup: powerup.texture = SUPER_POWERUP
	
	powerup_type_sprite.texture = GameManager.powerup_data[powerup_type].texture

func _process(delta: float) -> void:
	x += delta * SPEED
	velocity.y = sin(x * SIN_PER) * SIN_AMP
	position += velocity * delta
