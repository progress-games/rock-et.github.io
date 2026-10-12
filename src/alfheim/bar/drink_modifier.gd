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
	INITIAL_AUTOCLICK,
	COIN_CHANCE
}

const DESCRIPTIONS := {
	ModifyingStat.ASTEROIDS: "asteroid spawn rate",
	ModifyingStat.MINERAL_VALUE: "all mineral value",
	ModifyingStat.HIT_STRENGTH: "hit strength",
	ModifyingStat.HIT_SIZE: "hit size",
	ModifyingStat.CLICKS: "clicks",
	ModifyingStat.DIAMOND_CHANCE: "diamond drop chance",
	ModifyingStat.LIGHTNING_CHANCE: "lightning chance",
	ModifyingStat.INITIAL_BOOST: "initial boost",
	ModifyingStat.ERRATIC_ASTEROIDS: "erratic asteroids",
	ModifyingStat.INITIAL_AUTOCLICK: "initial autoclick",
	ModifyingStat.COIN_CHANCE: "coin drop chance"
}

@export var modifier_type: ModifierType
@export var modifying_stat: ModifyingStat
@export var amount: float

func get_img() -> String:
	return " [img " + "tooltip='" + \
		DESCRIPTIONS[modifying_stat] + "']"\
		+ "res://alfheim/bar/symbols/" + \
		ModifyingStat.find_key(modifying_stat).to_lower() + ".png" + "[/img]"

func get_text() -> String:
	var m = round(amount * 100) / 100
	match modifying_stat:
		ModifyingStat.ASTEROIDS:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "%" + get_img()
		ModifyingStat.MINERAL_VALUE:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "%" + get_img()
		ModifyingStat.HIT_STRENGTH:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "%" + get_img()
		ModifyingStat.HIT_SIZE:
			m = int((m - 1) * 100)
			return ("+" if modifier_type == ModifierType.POSITIVE else "") + str(m) + "%" + get_img()
		ModifyingStat.CLICKS:
			return ("+" if m > 0 else "") + str(int(m)) + get_img()
		ModifyingStat.DIAMOND_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "%" + get_img()
		ModifyingStat.COIN_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "%" + get_img()
		ModifyingStat.LIGHTNING_CHANCE:
			return "+" + str(int(ceil(m * 100))) + "%" + get_img()
		ModifyingStat.INITIAL_BOOST:
			return "+" + str(m) + "px" + get_img()
		ModifyingStat.ERRATIC_ASTEROIDS:
			if m <= 2:
				return "1x" + get_img()
			elif m <= 3:
				return "2x" + get_img()
			elif m <= 4:
				return "4x" + get_img()
			else:
				return "10x" + get_img()
		ModifyingStat.INITIAL_AUTOCLICK:
			return "+" + str(m) + "s" + get_img()
	
	return "lol what"
