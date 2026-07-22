extends Node2D

const SNOW_TRAIL = preload("uid://bnn3inflimj44")
const TRAIL_WIDTH := 3.
const UPDATE_DISTANCE = 3

var collision_shapes: Array[CollisionShape2D]
var particles: Array[CPUParticles2D]
var last_pos := Vector2(0, 0)
var active = false

@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(snow_entered)
	area.tree_exited.connect(func (): print_stack())

func clear_snow_trail() -> void:
	particles.map(func (x: CPUParticles2D): 
		x.one_shot = true
		x.finished.connect(func (): particles.erase(x))
	)
	
	var t = Timer.new()
	t.wait_time = 3
	t.one_shot = true
	t.timeout.connect(
		func ():
			if !active:
				collision_shapes.map(func (x): x.queue_free())
				collision_shapes.clear()
	)
	add_child(t)
	t.start()

func spawn_snow_trail() -> void:
	var mouse_pos = get_local_mouse_position()
	var dis = last_pos.distance_to(mouse_pos)
	
	if !active:
		active = true
		last_pos = mouse_pos
		collision_shapes.map(func (x): x.queue_free())
		collision_shapes.clear()
	elif dis < UPDATE_DISTANCE:
		return
	
	create_collision_shape(mouse_pos)
	spawn_snow_particles(mouse_pos)
	
	last_pos = mouse_pos

func snow_entered(body) -> void:
	pass#print_debug(body.has_meta("asteroid"))

func spawn_snow_particles(mouse_pos: Vector2) -> void:
	var new = SNOW_TRAIL.instantiate() as CPUParticles2D
	new.emitting = true
	new.position = mouse_pos
	new.emission_sphere_radius = TRAIL_WIDTH
	new.amount = new.amount * ceil(TRAIL_WIDTH / 10.)
	add_child(new)
	particles.append(new)

func create_collision_shape(mouse_pos: Vector2) -> void:
	var collision_shape = CollisionShape2D.new()
	collision_shape.position = mouse_pos
	collision_shape.shape = CircleShape2D.new()
	collision_shape.shape.radius = TRAIL_WIDTH
	
	area.add_child(collision_shape)
	collision_shapes.append(collision_shape)

func _process(_d: float) -> void:
	if Input.is_action_pressed("squall") && false:
		spawn_snow_trail()
	elif active:
		clear_snow_trail()
		active = false
