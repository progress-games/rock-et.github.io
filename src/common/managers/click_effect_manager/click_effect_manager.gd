extends Node

enum ClickType {
	AUTOCLICK_AREA,
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
	ClickType.AUTOCLICK_AREA: {
		StatType.EVERY: [1], # every [2, 3, 4] clicks
		StatType.FREQUENCY: 0.5, # every n seconds
		StatType.SIZE: 0.5, # size relative to player cursor size
		StatType.DURATION: 3 # duration in s
	},
	ClickType.BLACKHOLE: {
		StatType.EVERY: [1],
		StatType.PULL: 0.1, # rocks move at 1 speed towards centre
		StatType.SIZE: 0.8,
		StatType.DURATION: 4
	},
	ClickType.EXPLOSION: {
		StatType.EVERY: [1],
		StatType.DAMAGE: 3, # deals 5x damage
		StatType.SIZE: 2
	}
}

const DEFAULT_CLICKS := 100

var clicks: int = DEFAULT_CLICKS

## upgrade effect
func upgrade_effect(type: ClickType, stat_name: StatType, value: float, function: UpgradeType = UpgradeType.ADD) -> void:
	if type == ClickType.CLICKS:
		clicks += value
		return
	
	if stat_name == StatType.EVERY:
		stats[type][stat_name].append(int(value))
		return
	
	var val = stats[type][stat_name]
	match function:
		UpgradeType.ADD: val += value
		UpgradeType.MULT: val *= value
		UpgradeType.SUB: val -= value
		UpgradeType.DIV: val /= value
	
	stats[type][stat_name] = val
