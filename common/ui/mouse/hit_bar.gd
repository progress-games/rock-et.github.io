extends ColorRect

var progress := 0.0

func _process(delta: float) -> void:
	progress = min(progress + 0.005, 1)
	material.set_shader_parameter("progress", progress)
