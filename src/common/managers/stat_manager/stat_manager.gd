extends Node

"""
holds all of the player stats.

used to divert responsibilities from game_manager and
add additional logic for which stats to use when
"""

const BASE_PORTIONS: Array[int] = [10, 30, 50, 10]


@export var export_stats: Dictionary[String, Stat]

var stats: Dictionary[String, Stat]
var levels: Array
var portions_changed: bool = true

signal stat_upgraded(stat: Stat)

func _ready() -> void:
	_set_base_stats()

func _set_base_stats() -> void:
	var methods = {
		"fuel_capacity": func(u): 
				u.value = (u.value + 2) * 1.05
				u.cost = (u.cost + 8) * 1.15,
		
		"thruster_speed": func(u): 
				u.value += 1
				u.cost = (u.cost + 2) * 1.15,
			
		"mineral_value": func(u): 
				u.value *= 1.25
				u.cost = pow(u.cost, 1.2),

		"hit_size": func(u): 
				u.value = (u.value + 0.05) * 1.08
				u.cost = (u.cost + 5) * 1.4,
		
		"hit_strength": 
			 func(u): 
				u.value = (u.value + 0.1) * 1.05
				u.cost = (u.cost + 6) * 1.35,
		
		"crit_chance": func(u): 
				u.cost = pow(u.cost, 1.35),
		
		"lightning_length": func(u): 
				u.value += 1
				u.cost = pow(u.cost, 1.3),
		"lightning_damage": func(u): 
				u.value = (u.value + 2) * 1.3
				u.cost = pow(u.cost, 1.3),
		"lightning_chance": func(u): 
				u.value += 0.05
				u.cost *= 2,
		
		"red_damage": func(u): 
				u.value = (u.value + 0.05) * 1.05
				u.cost *= 1.6,
		"red_portion": func(u): 
				u.cost *= 1.3,
		"red_yield": func(u): 
				u.value = u.value + 0.05
				u.cost *= 1.75,
		
		"orange_damage": func(u): 
				u.value = (u.value + 0.3) * 1.1
				u.cost *= 1.6,
		"orange_portion": func(u): 
				u.cost *= 1.5,
		"orange_yield": func(u): 
				u.value = (u.value + 0.25) * 1.2
				u.cost *= 1.5,
		
		"green_damage": func(u): 
				u.value = (u.value + 0.2) * 1.1
				u.cost *= 1.8,
		"green_portion": func(u): 
				u.cost *= 1.5,
		"green_yield": func(u): 
				u.value = (u.value + 0.4) * 1.05
				u.cost *= 1.3,
		
		"blue_damage": func(u): 
				u.value = (u.value + 0.3) * 1.15
				u.cost = (u.cost + 50) * 1.8,
		"blue_portion": func(u): 
				u.cost *= 1.8,
		"blue_yield": func(u): 
				u.value = (u.value + 0.2) * 1.15
				u.cost = (u.cost + 60) * 1.7,
		
		"bar_replenish": func(u): 
				u.value = (u.value + 0.0005) * 1.05
				u.cost = (u.cost + 100) * 1.5,
		"rock_boost": func(u): 
				u.value += 0.01
				u.cost *= 2.2,
		
		"boost_distance": func(u):
				u.value += 0.1
				u.cost *= 2.5,
		"armour": func(u): 
				u.value -= 0.3
				u.cost *= 1.45,
		"boost_discount": func(u): 
				u.value = (u.value + 500) * 1.1
				u.cost *= 1.2,
		
		"powerup_duration": func(u): 
				u.value = (u.value + 0.2) * 1.03
				u.cost *= 1.2,
		"powerup_spawn_rate": func(u): 
				u.value = (u.value + 0.2) * 1.03
				u.cost *= 1.2,
		"powerup_ultra_chance": func(u): 
				u.value = (u.value + 0.03) * 1.01
				u.cost *= 1.2,
		
		"speed_boost": func(u): 
				u.value += 0.2
				u.cost *= 1.2,
		"fuel_boost": func(u): 
				u.value = (u.value + 0.5) * 1.03
				u.cost *= 1.2,
		"more_minerals": func(u): 
				u.value = (u.value + 0.2) * 1.03
				u.cost *= 1.2,
		"damage_boost": func(u): 
				u.value = (u.value + 0.2) * 1.03
				u.cost *= 1.2,
	}
	
	for n in export_stats.keys():
		var no_spaces = n.replace(" ", "_")
		stats.set(no_spaces, export_stats[n])
		stats[no_spaces].add_upgrade_method(methods[no_spaces])
		stats[no_spaces].stat_name = no_spaces

func get_stat(stat_name: String) -> Stat:
	if !stats.get(stat_name):
		push_error("No stat called: '" + stat_name + "'")
	return stats[stat_name]

## gets the portion width of a particular colour. levels is an array of int 
func get_portion(inp_colour: String) -> int:
	var colours: Array[String] = ["red", "orange", "green", "blue"]
	
	if !portions_changed: 
		return levels[colours.find(inp_colour)]
	
	levels = BASE_PORTIONS.duplicate()
	
	for i in colours.size():
		var colour = colours[i]
		for k in stats.get(colour + "_portion").level - 1:
			# adds 4 because we remove 1 from everything
			levels[i] += 4
			levels = levels.map(func (x): return x - 1)
	
	# all unleveled portions have 0 portion
	for i in levels.size():
		if stats.get(colours[i] + "_portion").level == 1:
			levels[i] = 0
	
	var sum = levels.reduce(func (a, x): return a + x, 0)
	levels = levels.map(func (x): return round((float(x) / sum) * 100))
	
	portions_changed = false
	return levels[colours.find(inp_colour)]

func get_colour(portion: float) -> String:
	var colours: Array[String] = ["red", "orange", "green", "blue"]
	var p = 0
	
	for colour in colours:
		if portion <= p + get_portion(colour):
			return colour
		p += get_portion(colour)
	
	return "blue"

func upgrade_stat(stat_name: String) -> void:
	if stat_name.find("portion"): portions_changed = true
	stats[stat_name].upgrade()
	stat_upgraded.emit(stats[stat_name])

func can_upgrade_stat(stat_name: String) -> bool:
	return not stats[stat_name].is_max() and \
		GameManager.player.can_afford(stats[stat_name].cost, stats[stat_name].mineral)
