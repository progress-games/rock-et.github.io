extends TextureButton

@export var state: GameManager.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE

func _on_pressed() -> void:
	GameManager.state_changed.emit(state)
	AudioManager.create_audio(sound_effect)
