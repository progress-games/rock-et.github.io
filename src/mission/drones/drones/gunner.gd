extends Drone

func shoot() -> void:
	current_ammo -= 1
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GUNNER_SHOT)
	
	shot.emit(create_bullet())
	
