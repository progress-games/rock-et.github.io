extends Node

var active_modifiers: Array[DrinkModifier]
var compiled_effects: Dictionary[DrinkModifier.ModifyingStat, float]

func _ready() -> void:
	GameManager.day_changed.connect(reset_effects)
	GameManager.state_changed.connect(func (s: Enums.State): if s == Enums.State.MISSION: compile_effects())

func reset_effects(_d) -> void:
	active_modifiers.clear()
	compiled_effects.clear()

func compile_effects() -> void:
	var v: float
	for m in active_modifiers:
		match m.modifying_stat:
			DrinkModifier.ModifyingStat.ASTEROIDS, DrinkModifier.ModifyingStat.MINERAL_VALUE, \
			DrinkModifier.ModifyingStat.HIT_STRENGTH, DrinkModifier.ModifyingStat.HIT_SIZE, \
			DrinkModifier.ModifyingStat.ERRATIC_ASTEROIDS:
				v = compiled_effects.get(m.modifying_stat, 1)
				v += m.amount - 1
				compiled_effects.set(m.modifying_stat, v)
			DrinkModifier.ModifyingStat.CLICKS:
				v = compiled_effects.get(m.modifying_stat, 1)
				compiled_effects.set(m.modifying_stat, v + m.amount)
			DrinkModifier.ModifyingStat.DIAMOND_CHANCE, DrinkModifier.ModifyingStat.LIGHTNING_CHANCE, \
			DrinkModifier.ModifyingStat.INITIAL_BOOST, DrinkModifier.ModifyingStat.INITIAL_AUTOCLICK:
				v = compiled_effects.get(m.modifying_stat, 0)
				compiled_effects.set(m.modifying_stat, v + m.amount)

func add_modifer(m: DrinkModifier) -> void:
	active_modifiers.append(m)

func get_stat(s: DrinkModifier.ModifyingStat):
	match s:
		DrinkModifier.ModifyingStat.ASTEROIDS, DrinkModifier.ModifyingStat.MINERAL_VALUE, \
		DrinkModifier.ModifyingStat.HIT_STRENGTH, DrinkModifier.ModifyingStat.HIT_SIZE:
			return compiled_effects.get(s, 1)
		DrinkModifier.ModifyingStat.CLICKS, DrinkModifier.ModifyingStat.DIAMOND_CHANCE, \
		DrinkModifier.ModifyingStat.LIGHTNING_CHANCE, DrinkModifier.ModifyingStat.INITIAL_AUTOCLICK, \
		DrinkModifier.ModifyingStat.INITIAL_BOOST, DrinkModifier.ModifyingStat.ERRATIC_ASTEROIDS:
			return compiled_effects.get(s, 0)
