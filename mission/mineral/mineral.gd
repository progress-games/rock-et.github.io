extends RigidBody2D

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const MIN_VELOCITY = 80

var mineral: GameManager.Mineral

func _ready() -> void:
	$Sprite2D.texture = GameManager.MINERAL_TEXTURES[mineral]

func _process(delta: float) -> void:
	if linear_velocity.length() < MIN_VELOCITY and not has_meta("mineral"): 
		set_meta("mineral", true)
