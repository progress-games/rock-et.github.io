extends Control

@onready var sfx: HSlider = $VBoxContainer/Sfx/Sfx
@onready var music: HSlider = $VBoxContainer/Music/Music
@onready var ambience: HSlider = $VBoxContainer/Ambience/Ambience

func _ready() -> void:
	sfx.value = Settings.get_setting(Settings.SettingType.SFX_VOLUME)
	music.value = Settings.get_setting(Settings.SettingType.MUSIC_VOLUME)
	ambience.value = Settings.get_setting(Settings.SettingType.AMBIENCE_VOLUME)
	
	Settings.setting_updated.connect(func (s, v): 
		if !SaveManager.loading_save: return
		match s:
			Settings.SettingType.SFX_VOLUME: sfx.value = v
			Settings.SettingType.MUSIC_VOLUME: music.value = v
			Settings.SettingType.AMBIENCE_VOLUME: ambience.value = v
	)

func slider_changed(v: float, s: Settings.SettingType) -> void:
	Settings.set_setting(s, int(v))
	if int(v) % 5 == 0: AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.SLIDER)

func on_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		
