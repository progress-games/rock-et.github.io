extends Node

"""
holds all of the player stats.

used to divert responsibilities from game_manager and
add additional logic for which stats to use when
"""

const BASE_PORTIONS: Array[int] = [10, 30, 52, 8]
@export var powerup_order: Array[Powerup.PowerupType]
@export var planet_stats: Dictionary[String, PlanetStat]
@export var export_stats: Dictionary[String, Stat]

var stats: Dictionary[String, Stat]
var levels: Array
var portions_changed: bool = true
var enabled_powerups: Array[Powerup.PowerupType] = [Powerup.PowerupType.SPEED_BOOST]

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
				u.value = (u.value + 0.1) * 1.1
				u.cost = pow(u.cost, 1.15),

		"hit_size": func(u): 
				u.value = (u.value + 0.05) * 1.08
				u.cost = (u.cost + 5) * 1.4,
		
		"hit_strength": 
			 func(u): 
				u.value = (u.value + 0.1) * 1.05
				u.cost = (u.cost + 6) * 1.35,
		
		"click_speed": func(u): 
				u.value = (u.value + 0.1)
				u.cost = pow(u.cost, 1.13),
		
		"autocollect": func (u):
				u.value += 1,
		
		"lightning_length": func(u): 
				u.value += 1
				u.cost = pow(u.cost, 1.3),
		"lightning_damage": func(u): 
				u.value = (u.value + 0.1) * 1.1
				u.cost = pow(u.cost, 1.3),
		"lightning_chance": func(u): 
				u.value += 0.04
				u.cost = (u.cost + 8) * 1.8,
		
		"red_damage": func(u): 
				u.value = (u.value + 0.05) * 1.05
				u.cost *= 1.6,
		"red_portion": func(u): 
				u.cost *= 1.3,
		"red_yield": func(u): 
				u.value = u.value + 0.07
				u.cost *= 1.75,
		
		"orange_damage": func(u): 
				u.value = (u.value + 0.1) * 1.1
				u.cost *= 1.6,
		"orange_portion": func(u): 
				u.cost *= 1.5,
		"orange_yield": func(u): 
				u.value = (u.value + 0.25) * 1.1
				u.cost *= 1.5,
		
		"green_damage": func(u): 
				u.value = (u.value + 0.15) * 1.1
				u.cost *= 1.8,
		"green_portion": func(u): 
				u.cost *= 1.5,
		"green_yield": func(u): 
				u.value = (u.value + 0.4) * 1.05
				u.cost *= 1.3,
		
		"blue_damage": func(u): 
				u.value = (u.value + 0.2) * 1.1
				u.cost *= 1.83,
		"blue_portion": func(u): 
				u.cost *= 1.8,
		"blue_yield": func(u): 
				u.value = (u.value + 0.15) * 1.05
				u.cost = (u.cost + 60) * 1.7,
		
		"bar_replenish": func(u): 
				u.value = (u.value + 0.0005) * 1.05
				u.cost = (u.cost + 100) * 1.5,
		"rock_boost": func(u): 
				u.value += 0.01
				u.cost *= 2.2,
		
		"boost_distance": func(u):
				u.value += 0.1
				u.cost = (u.cost + 100) * 1.15,
		"armour": func(u):
				if u.level == 7:
					u.tooltip = "fuel gained per corundum hit"
					u.display_format = Stat.DisplayType.ADD_TIME
					u.value = 0
					u.cost *= 2
				elif u.level < 7:
					u.value -= 0.3
					u.cost = (u.cost + 5) * 1.45
				else:
					u.value -= 0.1
					u.cost *= 1.6,
		"boost_discount": func(u): 
				u.value = (u.value + 0.05) * 1.04
				u.cost *= 1.4,
		
		"powerup_spawn_rate": func(u): 
				u.value -= 0.1
				u.cost = (u.cost + 8) * 1.3,
		"powerup_ultra_chance": func(u): 
				u.value = (u.value + 0.01) * 1.01
				u.cost *= 1.2,
		"unlocked_powerups": func (u):
				u.value += 1
				u.cost = (u.cost + 4) * 1.2,
		
		"speed_boost_powerup": func(u): 
				u.value *= 1.08
				u.cost = (u.cost + 3) * 1.2,
		"double_minerals_powerup": func(u): 
				u.value = u.value + 0.1
				u.cost = (u.cost + 4) * 1.2,
		"double_click_powerup": func(u): 
				u.value += 1
				u.cost = (u.cost + 3) * 1.2,
		"autoclick_powerup": func (u):
				u.value = (u.value + 0.3) * 1.02
				u.cost = (u.cost + 4) * 1.2,
		"insta_break_powerup": func (u):
				u.value = u.value + 1
				u.cost = (u.cost + 4) * 1.2,
		"more_rocks_powerup": func (u):
				u.value += 1
				u.cost *= (u.cost + 4) * 1.2,
		"pause_powerup": func (u):
				u.value += 0.3
				u.cost = (u.cost + 4) * 1.2,
		"size_up_powerup": func(u):
				u.value += 0.2
				u.cost = (u.cost + 4) * 1.2,
		"powerup_capacity": func (u):
				u.value += 1
				u.cost = (u.cost + 50) * 1.8,
		
		"exchange_duration": func (u):
				u.value += 3
				u.cost *= 1.7,
		
		"item_capacity": func (u):
				u.value += 1
				u.cost *= 2,
		"potion_capacity": func (u):
				u.value += 1
				u.cost *= 2,
		
		"freeze_chance": func (u):
				u.value += 0.05
				u.cost = (u.cost + 6) * 1.4,
		"freeze_duration": func (u):
				u.value += 0.5
				u.cost *= 1.35,
		"kruos_hit_size": func (u):
				u.value = (u.value + 0.1) * 1.1
				u.cost = (u.cost + 3) * 1.5,
		
		"shard_ability": func (_u): 
				pass,
		"shard_chance": func (u):
				u.value += 0.05
				u.cost = (u.cost + 5) * 1.4,
		"shard_amount": func (u):
				u.value += 1
				u.cost = (u.cost + 3) * 1.6,
		"shard_pierce": func (u):
				u.value += 1
				u.cost = (u.cost + 30) * 1.8,
		
		"daily_spins": func (u):
				u.cost = (u.cost + 40) * 2
				u.value += 1,
		"wheel_level": func (u):
				u.cost = (u.cost + 20) * 1.8
				u.value += 1
	}
	
	for n in export_stats.keys():
		var no_spaces = n.replace(" ", "_")
		stats.set(no_spaces, export_stats[n])
		stats[no_spaces].reset()
		if methods.get(no_spaces):
			stats[no_spaces].add_upgrade_method(methods[no_spaces])
		stats[no_spaces].stat_name = no_spaces
		if !stats[no_spaces].display_name:
			stats[no_spaces].display_name = n

func get_stat(stat_name: String) -> Stat:
	if !stats.get(stat_name):
		assert(false, "No stat called: '" + stat_name + "'")
	
	var alt_name = stat_name.replace("_", " ")
	if planet_stats.get(alt_name):
		return stats[planet_stats[alt_name].diverts_to[GameManager.planet].replace(" ", "_")]
	
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
			levels[i] += levels.reduce(func (a, x): return a + (1 if x > 1 else 0), 0)
			levels = levels.map(func (x): return max(1,x - 1))
	
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
