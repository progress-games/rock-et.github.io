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
	DIAMOND_CHANCE,
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
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "% asteroids"
		ModifyingStat.MINERAL_VALUE:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "% minerals"
		ModifyingStat.HIT_STRENGTH:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "% damage"
		ModifyingStat.HIT_SIZE:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "% hit size"
		ModifyingStat.CLICKS:
			return ("+" if m > 0 else "") + str(int(m)) + " clicks"
		ModifyingStat.DIAMOND_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "% diamond chance"
		ModifyingStat.LIGHTNING_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "% lightning chance"
		ModifyingStat.INITIAL_BOOST:
			return "+" + str(m) + "px boost"
		ModifyingStat.ERRATIC_ASTEROIDS:
			return "asteroids move \nerratically"
		ModifyingStat.INITIAL_AUTOCLICK:
			return "+" + str(m) + "s autoclick"
	
	return "lol what"
