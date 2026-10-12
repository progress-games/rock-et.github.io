extends MarginContainer

@onready var skip_dialogue: CheckButton = $VBoxContainer/CheckButton
@onready var h_slider: HSlider = $VBoxContainer/HBoxContainer/HSlider
@onready var autoclicker: CheckButton = $VBoxContainer/Autoclicker
@onready var cps: Label = $VBoxContainer/HBoxContainer/Label2
@onready var clicky: CheckButton = $VBoxContainer/Clicky

@onready var exchange_tick_rate: HSlider = $VBoxContainer/HBoxContainer2/HSlider
@onready var tick_rate: Label = $VBoxContainer/HBoxContainer2/Label2

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
				Settings.SettingType.EXCHANGE_TICK_RATE:
					var val = Settings.DEFAULTS[Settings.SettingType.EXCHANGE_TICK_RATE] / v
					tick_rate.text = str(snappedf(val, 0.1)) + "x"
					exchange_tick_rate.set_value_no_signal(val)
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
	
	exchange_tick_rate.value_changed.connect(
		func (value: float):
			Settings.set_setting(
				Settings.SettingType.EXCHANGE_TICK_RATE, 
				Settings.DEFAULTS[Settings.SettingType.EXCHANGE_TICK_RATE] * (1 / value))
			tick_rate.text = str(snappedf(value, 0.1)) + "x"
	)
	
	
