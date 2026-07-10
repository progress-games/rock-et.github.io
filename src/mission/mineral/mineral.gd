extends Area2D
class_name Mineral

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
const FRICTION = 0.87
const MIN_VELOCITY = 80
const DURATION = 5
const TEXTURE_WIDTH := 24
const TEXTURE_HEIGHT := 20
const CHANGES: Dictionary[int, int] = {1: 0, 10: 1, 100: 2, 1000: 3, 10000: 4}

var mineral: Enums.Mineral
var value: int
var mineral_tex: AtlasTexture
var timer: Timer
var flash_timer: Timer
var offset_timer: Timer
var dur: float
var linear_velocity: Vector2
var angular_velocity: float

func _ready() -> void:
	dur = DURATION * (1.0 / GameManager.get_item_stat("stopwatch", "fade_speed"))
	
	mineral_tex = mineral_tex.duplicate()
	mineral_tex.set_region(Rect2(
		CHANGES[value] * TEXTURE_WIDTH,
		0,
		TEXTURE_WIDTH,
		TEXTURE_HEIGHT
	))
	$Sprite2D.texture = mineral_tex.duplicate()
	
	var shape = RectangleShape2D.new()
	shape.size = Vector2($Sprite2D.texture.get_width(), $Sprite2D.texture.get_width())
	collision_shape.set_shape(shape)
	
	flash_timer = Timer.new()
	flash_timer.wait_time = dur / 18
	flash_timer.timeout.connect(func (): 
		visible = not visible
		flash_timer.wait_time = flash_timer.wait_time / 1.2
		)
	add_child(flash_timer)
	
	offset_timer = Timer.new()
	offset_timer.wait_time = dur / 2
	offset_timer.timeout.connect(flash_timer.start)
	add_child(offset_timer)
	
	timer = Timer.new()
	timer.wait_time = dur
	timer.timeout.connect(queue_free)
	add_child(timer)

func _process(dt: float) -> void:
	if linear_velocity.length() > 0.1:
		position += (linear_velocity * dt)
		rotation += (angular_velocity * dt)
		linear_velocity *= FRICTION
		angular_velocity *= FRICTION
	
	if timer.is_stopped() and not has_meta("mineral") and linear_velocity.length() < MIN_VELOCITY: 
		set_meta("mineral", true)
		timer.start()
		offset_timer.start()
		
		#for body in get_overlapping_areas():
			#if body is HitBox:
				#body._on_body_entered(self)
