extends Node

enum ClickType {
	AUTOCLICK,
	BLACKHOLE,
	EXPLOSION,
	CLICKS
}

enum UpgradeType {
	ADD,
	MULT,
	SUB,
	DIV
}

enum StatType {
	EVERY,
	FREQUENCY,
	SIZE,
	DURATION,
	PULL,
	DAMAGE
}

var stats: Dictionary[ClickType, Dictionary] = {
	ClickType.AUTOCLICK: {
		StatType.EVERY: [], # every [2, 3, 4] clicks
		StatType.FREQUENCY: 1, # clicks n times per second
		StatType.SIZE: 0.5, # size relative to player cursor size
		StatType.DURATION: 3 # duration in s
	},
	ClickType.BLACKHOLE: {
		StatType.EVERY: [],
		StatType.PULL: 0.25, # rocks move at 1 speed towards centre
		StatType.SIZE: 1,
		StatType.DURATION: 4
	},
	ClickType.EXPLOSION: {
		StatType.EVERY: [],
		StatType.DAMAGE: 3, # deals 5x damage
		StatType.SIZE: 1.5
	}
}

const DEFAULT_CLICKS := 10

var clicks: int = DEFAULT_CLICKS

signal effect_upgraded

## upgrade effect
func upgrade_effect(type: ClickType, stat_name: StatType, value: float, function: UpgradeType = UpgradeType.ADD) -> void:
	if type == ClickType.CLICKS:
		clicks += int(value)
		return
	
	if stat_name == StatType.EVERY:
		stats[type][stat_name].append(int(value) + 1)
		return
	
	var val = stats[type][stat_name]
	match function:
		UpgradeType.ADD: val += value
		UpgradeType.MULT: val *= value
		UpgradeType.SUB: val -= value
		UpgradeType.DIV: val /= value
	
	stats[type][stat_name] = val
	
	effect_upgraded.emit()
