extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _on_mouse_entered() -> void:
	sprite.material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	sprite.material.set_shader_parameter("width", 0)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.state_changed.emit(GameManager.State.MISSION)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.TAKE_OFF)
