extends TextureButton

func _on_mouse_entered() -> void:
	material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	material.set_shader_parameter("width", 0)
