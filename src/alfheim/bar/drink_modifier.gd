extends Resource
class_name DrinkModifier

enum ModifierType {
	POSITIVE,
	NEGATIVE
}

"""
asteroid spawn rate
mineral value
hit strength
hit size
clicks
gold drop chance
lightning chance
initial boost
erratic asteroids
initial autoclick
"""

enum ModifyingStat {
	ASTEROIDS,
	MINERAL_VALUE,
	HIT_STRENGTH,
	HIT_SIZE,
	CLICKS,
	GOLD_DROP_CHANCE,
	LIGHTNING_CHANCE,
	INITIAL_BOOST,
	ERRATIC_ASTEROIDS,
	INITIAL_AUTOCLICK
}

@export var modifier_type: ModifierType
@export var modifying_stat: ModifyingStat
@export var amount: float

func get_text() -> String:
	var m = snappedf(amount, 0.01)
	if str(m).ends_with(".0"): m = int(m)
	match modifying_stat:
		ModifyingStat.ASTEROIDS:
			return "x" + str(m) + " asteroids"
		ModifyingStat.MINERAL_VALUE:
			return "x" + str(m) + " minerals"
		ModifyingStat.HIT_STRENGTH:
			return "x" + str(m) + " damage"
		ModifyingStat.HIT_SIZE:
			return "x" + str(m) + " hit size"
		ModifyingStat.CLICKS:
			return ("+" if m > 0 else "") + str(int(m)) + " clicks"
		ModifyingStat.GOLD_DROP_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "% gold chance"
		ModifyingStat.LIGHTNING_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "% lightning chance"
		ModifyingStat.INITIAL_BOOST:
			return "+" + str(m) + "px boost"
		ModifyingStat.ERRATIC_ASTEROIDS:
			return "asteroids move \nerratically"
		ModifyingStat.INITIAL_AUTOCLICK:
			return "+" + str(m) + "s autoclick"
	
	return "lol what"
