extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _on_mouse_entered() -> void:
	sprite.material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	sprite.material.set_shader_parameter("width", 0)
