extends TextureButton

func _ready() -> void:
	mouse_entered.connect(func (): set_instance_shader_parameter("outline", 1))
	mouse_exited.connect(func (): set_instance_shader_parameter("outline", 0))
	toggled.connect(func (toggled_on): AudioManager.toggle_mute_audio(SoundEffect.SOUND_EFFECT_TYPE.CRITICAL_HIT, toggled_on))
