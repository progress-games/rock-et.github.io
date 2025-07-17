extends ColorRect

const INDENT = 5

var max_value: float;
var value: float

func _ready() -> void:
	GameManager.play.connect(func(): process_mode = PROCESS_MODE_INHERIT)
	GameManager.pause.connect(func(): process_mode = PROCESS_MODE_DISABLED)

func reset() -> void:
	max_value = GameManager.player.get_stat("fuel_capacity").value
	value = max_value

func _process(delta: float) -> void:
	value -= delta
	material.set_shader_parameter("progress", value / max_value)
