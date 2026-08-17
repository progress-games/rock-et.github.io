extends MarginContainer

@onready var check_button: CheckButton = $VBoxContainer/CheckButton

func _ready() -> void:
	check_button.toggled.connect(
		func (t):
			Settings.set_setting(Settings.SettingType.SKIP_DIALOGUE, t)
	)
