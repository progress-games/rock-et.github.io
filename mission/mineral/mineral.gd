extends RigidBody2D
class_name Mineral

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const MIN_VELOCITY = 80

var mineral: GameManager.Mineral
var value: int
var mineral_data: MineralData

func _ready() -> void:
	$Sprite2D.texture = mineral_data.get("drop_" + str(value))
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2($Sprite2D.texture.get_width(), $Sprite2D.texture.get_width())
	collision_shape.set_shape(shape)
	
func _process(delta: float) -> void:
	if linear_velocity.length() < MIN_VELOCITY and not has_meta("mineral"): 
		set_meta("mineral", true)
