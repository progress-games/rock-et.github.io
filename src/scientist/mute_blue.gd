extends TextureButton

const MUTED_ICON = preload("uid://ijuyscem47h8")
const UNMUTED_ICON = preload("uid://m40r3lhs7mvg")

func _ready() -> void:
	mouse_entered.connect(func (): 
		material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER);
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	
	mouse_exited.connect(func (): 
		material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	
	pressed.connect(func (): 
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
		AudioManager.toggle_mute_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT))
	
	AudioManager.sfx_muted.connect(
		func (sfx, m):
			if sfx == SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT:
				texture_normal = MUTED_ICON if m else UNMUTED_ICON)
