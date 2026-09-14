extends Node

const DEFAULTS := {
	SettingType.SFX_VOLUME: 35,
	SettingType.MUSIC_VOLUME: 50,
	SettingType.AMBIENCE_VOLUME: 50,
	SettingType.SKIP_DIALOGUE: false,
	SettingType.MUTE_DIALOGUE: false,
	SettingType.USE_AUTOCLICKER: false,
	SettingType.AUTOCLICKER_SPEED: 0,
	SettingType.CLICKY_LOCK: false,
	SettingType.POTION_KEYBINDINGS: [KEY_1, KEY_2, KEY_3],
	SettingType.POTION_CONTROLLER_BINDINGS: [JOY_BUTTON_X, JOY_BUTTON_Y, JOY_BUTTON_B],
	SettingType.USING_CONTROLLER: false
}

enum SettingType {
	SFX_VOLUME,
	MUSIC_VOLUME,
	AMBIENCE_VOLUME,
	SKIP_DIALOGUE,
	MUTE_DIALOGUE,
	USE_AUTOCLICKER,
	AUTOCLICKER_SPEED,
	CLICKY_LOCK,
	POTION_KEYBINDINGS,
	POTION_CONTROLLER_BINDINGS,
	USING_CONTROLLER
}

var values: Dictionary[SettingType, Variant]

signal setting_updated(s: SettingType, v: Variant)

func _ready() -> void:
	load_settings.call_deferred()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion and !get_setting(SettingType.USING_CONTROLLER):
		set_setting(SettingType.USING_CONTROLLER, true)
		return
	
	if get_setting(SettingType.USING_CONTROLLER):
		set_setting(SettingType.USING_CONTROLLER, false)

func get_setting(s: SettingType) -> Variant:
	return values.get(s, DEFAULTS.get(s))

func set_setting(s: SettingType, value: Variant) -> void:
	values.set(s, type_convert(value, typeof(DEFAULTS.get(s))))
	setting_updated.emit(s, values[s])
	save_settings()

func reset_settings() -> void:
	for setting in DEFAULTS.keys():
		values.set(setting, type_convert(DEFAULTS[setting], typeof(DEFAULTS[setting])))
		setting_updated.emit(setting, values[setting])
	save_settings()

func load_settings() -> void:
	if !FileAccess.file_exists("user://player_settings.txt"): reset_settings()
	var f = FileAccess.open("user://player_settings.txt", FileAccess.READ)
	var data = JSON.parse_string(f.get_line())
	
	for setting in data.keys():
		var s = int(setting)
		var v = type_convert(data[setting], typeof(DEFAULTS.get(s)))
		set_setting(s, v)

func save_settings() -> void:
	var f = FileAccess.open("user://player_settings.txt", FileAccess.WRITE)
	f.store_line(JSON.stringify(values))
