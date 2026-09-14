extends MarginContainer

@onready var skip_dialogue: CheckButton = $VBoxContainer/CheckButton
@onready var h_slider: HSlider = $VBoxContainer/HBoxContainer/HSlider
@onready var autoclicker: CheckButton = $VBoxContainer/Autoclicker
@onready var cps: Label = $VBoxContainer/HBoxContainer/Label2
@onready var clicky: CheckButton = $VBoxContainer/Clicky

func _ready() -> void:
	skip_dialogue.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.SKIP_DIALOGUE, t)
	)
	autoclicker.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.USE_AUTOCLICKER, t)
	)
	clicky.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.CLICKY_LOCK, t)
	)
	
	Settings.setting_updated.connect(
		func (s, v):
			match s:
				Settings.SettingType.SKIP_DIALOGUE: skip_dialogue.set_pressed_no_signal(v)
				Settings.SettingType.USE_AUTOCLICKER: autoclicker.set_pressed_no_signal(v)
				Settings.SettingType.CLICKY_LOCK: clicky.set_pressed_no_signal(v)
				Settings.SettingType.AUTOCLICKER_SPEED: 
					cps.text = str(int(ceil(v))) + "/cps"
					h_slider.set_value_no_signal(v)
	)
	
	h_slider.value_changed.connect(
		func (value: float):
			cps.text = str(int(ceil(value))) + "/cps"
			Settings.set_setting(Settings.SettingType.AUTOCLICKER_SPEED, int(ceil(value)))
	)
	
	GameManager.planet_changed.connect(
		func (p: Enums.Planet):
			if p == Enums.Planet.KRUOS:
				autoclicker.tooltip_text = "only available on dyrt"
	)
