extends Node

enum TempestType {
	SNOW_TRAIL,
	HAILSTORM
}

enum StatType {
	CHARGE,
	DAMAGE,
	SLOW_AMOUNT,
	WIDTH,
	MELT,
	FREEZE_DURATION,
	PIERCE,
	SPAWN_RATE
}


var tempest_stats: Dictionary[TempestType, Dictionary] = {
	TempestType.SNOW_TRAIL: {
		StatType.CHARGE: 1.,
		StatType.DAMAGE: 0.1,
		StatType.SLOW_AMOUNT: 0.1,
		StatType.WIDTH: 5,
		StatType.MELT: 1.
	},
	TempestType.HAILSTORM: {
		StatType.CHARGE: 1.,
		StatType.DAMAGE: 3.,
		StatType.SPAWN_RATE: 0.1,
		StatType.FREEZE_DURATION: 0.5,
		StatType.PIERCE: 1
	}
}

func get_stat(t: TempestType, s: StatType) -> float:
	return tempest_stats[t][s]

func format_snow_desc(s: StatType, a: float) -> String:
	match s:
		StatType.CHARGE:
			return "+" + str(a) + "s of charge"
	
	return ""

func format_desc(t: TempestType, s: StatType, a: float) -> String:
	match t:
		TempestType.SNOW_TRAIL:
			return format_snow_desc(s, a)
	
	return ""
