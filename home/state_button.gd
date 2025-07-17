extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

@export var state: GameManager.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE

func _on_mouse_entered() -> void:
	sprite.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(GameManager.MouseState.HOVER)

func _on_mouse_exited() -> void:
	sprite.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(GameManager.MouseState.DEFAULT)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		GameManager.state_changed.emit(state)
		AudioManager.create_audio(sound_effect)
