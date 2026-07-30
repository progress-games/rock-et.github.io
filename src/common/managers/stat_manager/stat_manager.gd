extends Node

"""
holds all of the player stats.

used to divert responsibilities from game_manager and
add additional logic for which stats to use when
"""

const STALL_LEVELS = [
	"ayi sells potions",
	"item and potion capacity during your flights can be upgraded",
	"ayi comes every 2 days instead of every 4",
	"items and potions can be rolled once",
	"items can be sold in groups of up to 5",
	"max level!"
]

const BASE_PORTIONS: Array[int] = [10, 30, 52, 8]
@export var powerup_order: Array[Powerup.PowerupType]
@export var planet_stats: Dictionary[String, PlanetStat]
@export var export_stats: Dictionary[String, Stat]

var stats: Dictionary[String, Stat]
var levels: Array
var portions_changed: bool = true
var enabled_powerups: Array[Powerup.PowerupType] = [Powerup.PowerupType.DOUBLE_MINERALS]

signal stat_upgraded(stat: Stat)

func _ready() -> void:
	_set_base_stats()

func _set_base_stats() -> void:
	var methods = {
		"fuel_capacity": func(u): 
				u.value = (u.value + 2) * 1.05
				u.cost = (u.cost + 12) * 1.3,
		"thruster_speed": func(u): 
				u.value += 1
				u.cost = (u.cost + 8) * 1.3,
		"mineral_value": func(u): 
				u.value = (u.value + 0.1)
				u.cost = (u.cost + 15) * 1.6,

		"hit_size": func(u): 
				u.value = (u.value + 0.1)
				u.cost = (u.cost + 12) * 1.7,
		
		"hit_strength": 
			 func(u): 
				u.value = (u.value + 0.1)
				u.cost = (u.cost + 10) * 1.6,
		
		"click_speed": func(u): 
				u.value = (u.value + 0.1)
				u.cost = pow(u.cost, 1.13),
		
		"autocollect": func (u):
				u.value += 1,
		
		"lightning_length": func(u): 
				u.value += 1
				u.cost = (u.cost + 80) * 1.7,
		"lightning_damage": func(u): 
				u.value = u.value + int(ceil(u.value * 0.5)) + 1
				u.cost = (u.cost + 30) * 1.7,
		"lightning_chance": func(u): 
				u.value += 0.05
				u.cost = (u.cost + 45) * 1.6,
		
		"red_power": func(u): 
				u.value += 1
				u.cost = (u.cost + 24) * 2,
		"red_portion": func(u): 
				u.cost *= 1.3,
		"red_yield": func(u): 
				u.value = u.value + 0.07
				u.cost *= 1.75,
		
		"orange_power": func(u): 
				u.value += 1
				u.cost = (u.cost + 10) * 1.7,
		"orange_portion": func(u): 
				u.cost *= 1.5,
		"orange_yield": func(u): 
				u.value = (u.value + 0.25) * 1.1
				u.cost *= 1.5,
		
		"green_power": func(u): 
				u.value += 1
				u.cost = (u.cost + 5) * 1.65,
		"green_portion": func(u): 
				u.cost *= 1.5,
		"green_yield": func(u): 
				u.value = (u.value + 0.3) * 1.05
				u.cost *= 1.4,
		
		"blue_power": func(u): 
				u.value += 1
				u.cost = (u.cost + 5) * 1.5,
		"blue_portion": func(u): 
				u.cost *= 1.8,
		"blue_yield": func(u): 
				u.value = (u.value + 0.5) * 1.05
				u.cost = (u.cost + 60) * 1.6,
		
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
				u.value -= 0.3
				u.cost = (u.cost + 5) * 1.3,
		"boost_discount": func(u): 
				u.value = (u.value + 0.05) * 1.04
				u.cost *= 1.4,
		
		"powerup_spawn_rate": func(u): 
				u.value -= 0.1
				u.cost = (u.cost + 8) * 1.3,
		"powerup_ultra_chance": func(u): 
				u.value = (u.value + 0.05) * 1.01
				u.cost *= 1.4,
		"unlocked_powerups": func (u):
				u.value += 1
				u.cost = (u.cost + 4) * 1.1,
		
		"speed_boost_powerup": func(u): 
				u.value *= 1.08
				u.cost = (u.cost + 3) * 1.1,
		"double_minerals_powerup": func(u): 
				u.value += 5
				u.cost = (u.cost + 4) * 1.1,
		"double_click_powerup": func(u): 
				u.value += 1
				u.cost = (u.cost + 3) * 1.1,
		"autoclick_powerup": func (u):
				u.value += 0.2
				u.cost = (u.cost + 4) * 1.1,
		"insta_break_powerup": func (u):
				u.value += 1
				u.cost = (u.cost + 4) * 1.1,
		"more_rocks_powerup": func (u):
				u.value += 1
				u.cost *= (u.cost + 4) * 1.1,
		"pause_powerup": func (u):
				u.value += 0.3
				u.cost = (u.cost + 4) * 1.1,
		"size_up_powerup": func(u):
				u.value += 0.1
				u.cost = (u.cost + 4) * 1.1,
		"powerup_capacity": func (u):
				u.value += 1
				u.cost = (u.cost + 30) * 1.5,
		
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
				u.value += 0.1
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
				u.cost = (u.cost + 5) * 1.8
				u.value += 1,
		"wheel_level": func (u):
				u.cost = (u.cost + 20) * 1.8
				u.value += 1,
		
		"stall_level": func (u):
				u.cost = u.cost * 2 + 50
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

## damage, size, mineral
func get_portion_power(colour: String, stat: String, next = false) -> float:
	var scales = {
		"damage": 2,
		"size": 25.,
		"mineral": 100.
	}
	return 1. + (get_stat(colour + "_power").value - (1. if !next else 0.)) / scales[stat]

func get_stall_current_desc() -> String:
	return "[color=#2e222f]stall upgrade:[/color] " + STALL_LEVELS[get_stat("stall_level").level - 1]

func can_upgrade_stat(stat_name: String) -> bool:
	return not stats[stat_name].is_max() and \
		GameManager.player.can_afford(stats[stat_name].cost, stats[stat_name].mineral)
