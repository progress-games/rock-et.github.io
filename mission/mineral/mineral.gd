extends RigidBody2D
class_name Mineral

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const MIN_VELOCITY = 80
const DURATION = 5
const TEXTURE_WIDTH := 22
const TEXTURE_HEIGHT := 14
const CHANGES :Dictionary[int, int] = {1: 0, 25: 1, 500: 2, 2500: 3, 10000: 4}

var mineral: Enums.Mineral
var value: int
var mineral_tex: AtlasTexture
var timer: Timer
var flash_timer: Timer

func _ready() -> void:
	mineral_tex.set_region(Rect2(
		CHANGES[value] * TEXTURE_WIDTH,
		0,
		TEXTURE_WIDTH,
		TEXTURE_HEIGHT
	))
	$Sprite2D.texture = mineral_tex
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2($Sprite2D.texture.get_width(), $Sprite2D.texture.get_width())
	collision_shape.set_shape(shape)
	
	flash_timer = Timer.new()
	flash_timer.wait_time = 0.3
	flash_timer.timeout.connect(func (): 
		visible = not visible
		flash_timer.wait_time = flash_timer.wait_time / 1.2)
	add_child(flash_timer)
	
func _process(delta: float) -> void:
	if linear_velocity.length() < MIN_VELOCITY and not has_meta("mineral"): 
		set_meta("mineral", true)
		
		timer = Timer.new()
		timer.wait_time = DURATION
		timer.timeout.connect(queue_free)
		add_child(timer)
		timer.start()
		
	if timer != null and timer.time_left < DURATION / 2 and flash_timer.is_stopped():
		flash_timer.start()
