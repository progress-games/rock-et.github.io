extends Control

@onready var sfx: HSlider = $VBoxContainer/Sfx/Sfx
@onready var music: HSlider = $VBoxContainer/Music/Music
@onready var ambience: HSlider = $VBoxContainer/Ambience/Ambience
@onready var speaking_sfx: CheckButton = $VBoxContainer/SpeakingSFX

func _ready() -> void:
	Settings.setting_updated.connect(func (s, v): 
		match s:
			Settings.SettingType.SFX_VOLUME: sfx.set_value_no_signal(v)
			Settings.SettingType.MUSIC_VOLUME: music.set_value_no_signal(v)
			Settings.SettingType.AMBIENCE_VOLUME: ambience.set_value_no_signal(v)
			Settings.SettingType.MUTE_DIALOGUE: speaking_sfx.set_pressed_no_signal(v)
	)
	
	speaking_sfx.toggled.connect(func (toggled_on):
		Settings.set_setting(Settings.SettingType.MUTE_DIALOGUE, toggled_on))

func slider_changed(v: float, s: Settings.SettingType) -> void:
	Settings.set_setting(s, int(v))
	if int(v) % 5 == 0: AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)

func on_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		
