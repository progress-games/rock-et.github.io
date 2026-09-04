extends MarginContainer

@onready var check_button: CheckButton = $VBoxContainer/CheckButton
@onready var h_slider: HSlider = $VBoxContainer/HBoxContainer/HSlider
@onready var autoclicker: CheckButton = $VBoxContainer/Autoclicker
@onready var cps: Label = $VBoxContainer/HBoxContainer/Label2

func _ready() -> void:
	check_button.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.SKIP_DIALOGUE, t)
	)
	autoclicker.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.USE_AUTOCLICKER, t)
	)
	
	h_slider.value_changed.connect(
		func (value: float):
			cps.text = str(int(ceil(value))) + "/cps"
			Settings.set_setting(Settings.SettingType.AUTOCLICKER_SPEED, int(ceil(value)))
	)
