extends Resource
class_name HitData

var damage_mult: float = 1.

var lightning_chance_increase: float = 0.
var lightning_chance_multiplier: float = 1.
var freeze_dur: float = 0.

var burn_dur: float = 0.

# does this much damage every 0.5s
var burn_damage: float = 0.

var bauxite_chance: float = 0.

var tephra_chance: float = 0.

var crit_chance: float = 0.

var life_steal_chance: float = 0.

func get_copy() -> HitData:
	var h = HitData.new()
	h.damage_mult = damage_mult
	h.lightning_chance_multiplier = lightning_chance_multiplier
	h.freeze_dur = freeze_dur 
	h.burn_damage = burn_damage
	h.burn_dur = burn_dur
	h.bauxite_chance = bauxite_chance
	h.tephra_chance = tephra_chance
	h.crit_chance = crit_chance
	return h
