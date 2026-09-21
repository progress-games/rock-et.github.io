extends Area2D
class_name Powerup

const SIN_AMP := 50
const SIN_PER := 5
const SPEED := 2
const SUPER_POWERUP := preload("res://mission/powerups/super_powerup.png")
const SUPER_COLOUR := Color("f9c22b")

enum PowerupType {
	SNOW_TRAIL, # creates a Npx wide snow trail for 3s
	LASER, # next n rocks are instantly broken
	MORE_ROCKS, # spawns 5 rocks
	SIZE_UP, # target size up
	GOLDEN_ASTEROID, # spawns 1 golden asteroid
	EXPLOSION, # creates 5px wide explosion
	LOCK_ON, # the next click effect spawns in this location
	TIPSY, # drink effects are doubled for 3s
	#aim_assist,
	#starts a combo,
	#spawns a drone
	# creates a laser across the screen
	#damage_boost
	#more_minerals
}

# order:
# explosion, laser, more rocks, snow trail, lock on, size up, tipsy, golden asteroid

@onready var powerup: Sprite2D = $Powerup
@onready var powerup_type_sprite: Sprite2D = $PowerupType
@onready var trail: GPUParticles2D = $Trail

var super_powerup: bool

var velocity: Vector2
var powerup_type: PowerupType = PowerupType.EXPLOSION
var x := 0.0

func _ready() -> void:
	#if powerup_type == PowerupType.SNOW_TRAIL:
		#powerup_type_sprite.material = null
	
	if super_powerup: 
		powerup.texture = SUPER_POWERUP
		trail.modulate = SUPER_COLOUR
	
	powerup_type_sprite.texture = GameManager.powerup_data[powerup_type].texture
	
	trail.process_material.direction.x = clamp(velocity.x * -1, -1, 1)

func _process(delta: float) -> void:
	x += delta * SPEED
	velocity.y = sin(x * SIN_PER) * SIN_AMP
	position += velocity * delta
