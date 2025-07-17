extends TextureButton

@export var state: GameManager.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE

func _on_pressed() -> void:
	GameManager.state_changed.emit(state)
	AudioManager.create_audio(sound_effect)


func _on_mouse_entered() -> void:
	GameManager.set_mouse_state.emit(GameManager.MouseState.HOVER)


func _on_mouse_exited() -> void:
	GameManager.set_mouse_state.emit(GameManager.MouseState.DEFAULT)
