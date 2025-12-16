extends Control

var day: int = 1

@onready var buttons := {
	"mute_sfx": $NinePatchRect/VBoxContainer/MuteSFX,
	"mute_ambience": $NinePatchRect/VBoxContainer/MuteAmbience,
	"load_save": $NinePatchRect/VBoxContainer/HBoxContainer/Button,
	"increase": $NinePatchRect/VBoxContainer/HBoxContainer/VBoxContainer/Increase,
	"decrease": $NinePatchRect/VBoxContainer/HBoxContainer/VBoxContainer/Decrease
}

func _on_mute_sfx_toggled(toggled_on: bool) -> void:
	AudioManager.muted = toggled_on
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	buttons.mute_sfx.text = "unmute sfx" if toggled_on else "mute sfx"

func _on_mute_ambience_toggled(toggled_on: bool) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	AudioManager.ambience_muted = toggled_on
	buttons.mute_ambience.text = "unmute ambience" if toggled_on else "mute ambience"
	var m = AudioManager.muted
	AudioManager.muted = true
	if GameManager.state == Enums.State.SETTINGS:
		GameManager.state_changed.emit(Enums.State.SETTINGS)
	AudioManager.muted = m

func change_day(dir: int = 0) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	var new = max(2, day + dir)
	if SaveManager.save_exists("day" + str(new)):
		day = new
		buttons.load_save.text = "load day " + str(day)

func load_save() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	SaveManager.loading_save = true
	SaveManager.load_save("day" + str(day))

func on_hover(b: String) -> void:
	match b:
		"decrease": buttons.decrease.material.set_shader_parameter("width", 1)
		"increase": buttons.increase.material.set_shader_parameter("width", 1)

func off_hover(b: String) -> void:
	match b:
		"decrease": buttons.decrease.material.set_shader_parameter("width", 0)
		"increase": buttons.increase.material.set_shader_parameter("width", 0)
		
