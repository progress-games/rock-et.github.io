extends Control


func _on_mute_sfx_toggled(toggled_on: bool) -> void:
	AudioManager.muted = toggled_on
	$NinePatchRect/MuteSFX.text = "unmute sfx" if toggled_on else "mute sfx"

func _on_mute_ambience_toggled(toggled_on: bool) -> void:
	AudioManager.ambience_muted = toggled_on
	$NinePatchRect/MuteAmbience.text = "unmute ambience" if toggled_on else "mute ambience"
	var m = AudioManager.muted
	AudioManager.muted = true
	if GameManager.state == Enums.State.SETTINGS:
		GameManager.state_changed.emit(Enums.State.SETTINGS)
	AudioManager.muted = m
