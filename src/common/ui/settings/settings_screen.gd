extends Control

var day: int = 1

@onready var buttons := {
	"load_save": $NinePatchRect/HBoxContainer/VBoxContainer/HBoxContainer/Button,
	"increase": $NinePatchRect/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Increase,
	"decrease": $NinePatchRect/HBoxContainer/VBoxContainer/HBoxContainer/VBoxContainer/Decrease
}
@onready var sfx: HSlider = $NinePatchRect/HBoxContainer/VBoxContainer/Sfx/HSlider
@onready var music: HSlider = $NinePatchRect/HBoxContainer/VBoxContainer/Sfx2/HSlider
@onready var ambience: HSlider = $NinePatchRect/HBoxContainer/VBoxContainer/Sfx3/HSlider

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

func change_day(dir: int = 0) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	
	var d = DirAccess.open("user://")
	var files = d.get_files()
	var saves = []
	for f in files:
		if !f.contains("day"): continue
		var s = f.trim_suffix(".save")
		if SaveManager.save_exists(s):
			saves.append(int(s))
	
	saves.sort()
	
	var i = saves.find(day)
	if i == -1:
		day = saves.front() if dir > 0 else saves.back()
	else:
		day = saves[(i + dir) % saves.size()]
	
	buttons.load_save.text = "load day " + str(day)

func load_save() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	
	SaveManager.loading_save = true
	SaveManager.load_save("day" + str(day))
	SaveManager.loading_save = false

func on_hover(b: String = "") -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	match b:
		"decrease": buttons.decrease.material.set_shader_parameter("width", 1)
		"increase": buttons.increase.material.set_shader_parameter("width", 1)

func off_hover(b: String = "") -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	match b:
		"decrease": buttons.decrease.material.set_shader_parameter("width", 0)
		"increase": buttons.increase.material.set_shader_parameter("width", 0)
		
