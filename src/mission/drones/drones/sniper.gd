extends Drone

const LINE_COLOUR := Color(0.682, 0.137, 0.204, 1.0)

var line: Line2D

func _ready() -> void:
	super._ready()
	
	line = Line2D.new()
	line.width = 1
	line.default_color = LINE_COLOUR
	line.z_index = -5
	add_child(line)
	line.global_position = Vector2.ZERO

func shoot() -> void:
	super.shoot()
	
	current_ammo -= 1
	shot.emit(create_bullet())

func _process(delta: float) -> void:
	super._process(delta)
	
	if closest_asteroid != null:
		closest_asteroid.material.set_shader_parameter("width", 0)
	
	request_closest_asteroid.emit()
	if closest_asteroid == null:
		return
	
	closest_asteroid.material.set_shader_parameter("width", 1)
	closest_asteroid.material.set_shader_parameter("color", LINE_COLOUR)
	
	line.global_position = Vector2.ZERO
	line.clear_points()
	line.add_point(global_position + shot_point.position)
	line.add_point(closest_asteroid.global_position)
