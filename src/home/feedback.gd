extends TextureButton

func pressed() -> void:
	material.set_shader_parameter("color", Color.WHITE)
	OS.shell_open(GameManager.FEEDBACK_LINK)

func hover() -> void:
	material.set_shader_parameter('width', 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover() -> void:
	material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
