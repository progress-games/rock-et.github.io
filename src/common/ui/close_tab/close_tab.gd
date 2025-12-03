extends TextureButton

@export var state: Enums.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE

func _on_pressed() -> void:
	if GameManager.state == Enums.State.MISSION: return 
	GameManager.state_changed.emit(state)
	GameManager.show_inventory.emit()
	AudioManager.create_audio(sound_effect)
	SaveManager.store_save()

func _on_mouse_entered() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func _on_mouse_exited() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
