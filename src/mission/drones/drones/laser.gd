extends Drone

const LINE_COLOUR := Color(0.941, 0.31, 0.471, 1.0)

var line: Line2D

var tick_rate_timer: float = 1.

var laser_damage: float

func _ready() -> void:
	super._ready()
	
	line = Line2D.new()
	line.width = 3
	line.default_color = LINE_COLOUR
	line.z_index = -5
	add_child(line)
	line.global_position = Vector2.ZERO
	
	laser_damage = drone_stats.get_stat(DroneEnums.StatType.LASER_DPS)

func shoot() -> void:
	pass

func _process(delta: float) -> void:
	super._process(delta)
	
	line.visible = current_ammo > 0
	if current_ammo <= 0:
		return
	
	if closest_asteroid != null:
		closest_asteroid.material.set_shader_parameter("width", 0)
	
	request_closest_asteroid.emit()
	if closest_asteroid == null:
		return
	
	set_angle()
	closest_asteroid.material.set_shader_parameter("width", 3)
	closest_asteroid.material.set_shader_parameter("color", LINE_COLOUR)
	
	var rng = RandomNumberGenerator.new()
	
	closest_asteroid.hit(laser_damage * delta, rng.rand_weighted([0.9, 0.1]))
	current_ammo -= 1
	used_ammo.emit()
	
	line.global_position = Vector2.ZERO
	line.clear_points()
	line.add_point(global_position + shot_point.position)
	line.add_point(closest_asteroid.global_position)
