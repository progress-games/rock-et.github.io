extends Drone

func shoot() -> void:
	consume_ammo()
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.GUNNER_SHOT)
	
	shot.emit(create_bullet())
	
