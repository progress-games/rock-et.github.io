extends Node

enum TempestType {
	SNOW_TRAIL,
	HAILSTORM
}

enum Operation {
	ADD,
	MULT
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

const OPERATION_SYMBOLS = {
	Operation.ADD: "+",
	Operation.MULT: "x"
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

func format_snow_desc(s: StatType, a: float, o: Operation) -> String:
	var v = str(snappedf(a, 0.01))
	match s:
		StatType.CHARGE:
			match o:
				Operation.ADD: return "+" + v + "s of charge time"
				Operation.MULT: return "x" + v + " total charge time"
		StatType.DAMAGE:
			match o:
				Operation.ADD: return "+" + v + " tick damage"
				Operation.MULT: return "x" + v + " tick damage"
		StatType.SLOW_AMOUNT:
			return "asteroids move " + str(int(ceil(a * 100))) + "% slower"
		StatType.WIDTH:
			return "snow trail is " + str(int(ceil(a))) + "px wider"
		StatType.MELT:
			return "snow trail takes +" + v + "s to melt"
	
	return ""

func format_desc(t: TempestType, s: StatType, a: float, o: Operation) -> String:
	match t:
		TempestType.SNOW_TRAIL:
			return format_snow_desc(s, a, o)
	
	return ""
