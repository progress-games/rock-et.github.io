extends Node

var active_modifiers: Array[DrinkModifier]
var compiled_effects: Dictionary[DrinkModifier.ModifyingStat, float]

func _ready() -> void:
	GameManager.day_changed.connect(reset_effects)
	GameManager.state_changed.connect(func (s: Enums.State): 
		if s == Enums.State.MISSION: compile_effects(compiled_effects, active_modifiers))

func reset_effects(_d) -> void:
	active_modifiers.clear()
	compiled_effects.clear()

# compile effects, create temporary drink modifiers to use get_text() to print them
func get_effects(modifier_type: DrinkModifier.ModifierType) -> String:
	var totals = {}
	var s = ""
	compile_effects(totals,
		active_modifiers.filter(func (m): return m.modifier_type == modifier_type))
	
	for modifying_stat in totals.keys():
		var temp = DrinkModifier.new()
		temp.amount = totals[modifying_stat]
		temp.modifier_type = modifier_type
		temp.modifying_stat = modifying_stat
		s += "\n" + temp.get_text()
	
	return s.lstrip("\n")

func compile_effects(dict: Dictionary, modifiers: Array[DrinkModifier]) -> void:
	var v: float
	for m in modifiers:
		match m.modifying_stat:
			DrinkModifier.ModifyingStat.ASTEROIDS, DrinkModifier.ModifyingStat.MINERAL_VALUE, \
			DrinkModifier.ModifyingStat.HIT_STRENGTH, DrinkModifier.ModifyingStat.HIT_SIZE, \
			DrinkModifier.ModifyingStat.ERRATIC_ASTEROIDS:
				v = dict.get(m.modifying_stat, 1)
				dict.set(m.modifying_stat, v * m.amount)
			DrinkModifier.ModifyingStat.CLICKS:
				v = dict.get(m.modifying_stat, 1)
				dict.set(m.modifying_stat, v + m.amount)
			DrinkModifier.ModifyingStat.DIAMOND_CHANCE, DrinkModifier.ModifyingStat.LIGHTNING_CHANCE, \
			DrinkModifier.ModifyingStat.INITIAL_BOOST, DrinkModifier.ModifyingStat.INITIAL_AUTOCLICK:
				v = dict.get(m.modifying_stat, 0)
				dict.set(m.modifying_stat, v + m.amount)

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
