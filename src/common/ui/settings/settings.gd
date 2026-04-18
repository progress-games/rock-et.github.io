extends Node

enum SettingType {
	SFX_VOLUME,
	MUSIC_VOLUME,
	AMBIENCE_VOLUME
}

var values: Dictionary[SettingType, Variant] = {
	SettingType.SFX_VOLUME: 50,
	SettingType.MUSIC_VOLUME: 50,
	SettingType.AMBIENCE_VOLUME: 50
}

signal setting_updated(s: SettingType, v: Variant)

func get_setting(s: SettingType) -> Variant:
	return values[s]

func set_setting(s: SettingType, value: Variant) -> void:
	values[s] = type_convert(value, typeof(values[s]))
	setting_updated.emit(s, values[s])
