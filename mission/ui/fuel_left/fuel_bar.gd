extends ColorRect

const INDENT = 5

var max_value: float;
var value: float

func _ready() -> void:
	max_value = GameManager.player.get_stat("fuel_capacity").value
	value = max_value
	position = GameManager.location + Vector2(160 - size.x, - 90) - Vector2(INDENT, -INDENT)

func _process(delta: float) -> void:
	global_position.y -= delta * GameManager.player.get_stat("thruster_speed").value
	value -= delta
	material.set_shader_parameter("progress", value / max_value)
