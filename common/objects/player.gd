extends Object
class_name Player

var stats: Dictionary
var minerals: Dictionary
var hit_strength: String
signal stat_upgraded(stat: Stat)
signal mineral_discovered(mineral: Enums.Mineral)

var discovered: Dictionary[Enums.EnumType, Dictionary] = {}
var portions_changed = true
var levels: Array
var olivine_fragments: float = 0;

const BASE_PORTIONS: Array[int] = [20, 25, 45, 10]

func _init() -> void:
	set_base_stats()
	
	for enum_type in Enums.EnumType.keys():
		discovered[Enums.EnumType[enum_type]] = {}
	
	for name in Enums.Mineral.keys():
		minerals[Enums.Mineral[name]] = 0
	
	GameManager.add_mineral.connect(_add_mineral)
	
	GameManager.state_changed.connect(func (state): discover_state(state))
	
	for state in GameManager.day_requirement.keys():
		if GameManager.day_requirement[state] == 0:
			discover_state(state)

func set_base_stats() -> void:
	stats = {
		"fuel_capacity": Stat.new({
			"name": "fuel_capacity",
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value = (u.value + 1.5) * 1.2
				u.cost.amount = (u.value + 3.) * 1.8,
			"update_display": func (u):
				if u.value >= 60:
					u.display_value = str(round(u.value / 60))  + "m " + str(int(u.value) % 60) + "s"
				else:
					u.display_value = str(int(u.value) % 60) + "s",
			"value": 10,
			"tooltip": "fly for longer",
			"max": 10}),
		
		"thruster_speed": Stat.new({
			"name": "thruster_speed",
			"cost": {
				"amount": 16, 
				"mineral": Enums.Mineral.AMETHYST
			},
			"upgrade_method": func(u): 
				u.value += 2
				u.cost.amount = (u.cost.amount + 5.) * 2, 
			"update_display": func (u):
				u.display_value = str(u.value) + "px/s",
			"value": 0,
			"tooltip": "fly higher for better minerals",
			"max": 10}),
			
		"mineral_value": Stat.new({
			"name": "mineral_value",
			"cost": {
				"amount": 32, 
				"mineral": Enums.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value *= 1.2
				u.cost.amount = pow(u.cost.amount, 1.2), 
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 1000.0) + "x",
			"value": 1,
			"tooltip": "more minerals per asteroid",
			"max": 10}),

		"hit_size": Stat.new({
			"name": "hit_size",
			"cost": {
				"amount": 7, 
				"mineral": Enums.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value += 0.2
				u.cost.amount = pow(u.cost.amount, 1.2),
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 0.4
		}),
		"hit_strength": Stat.new({
			"name": "hit_strength",
			"cost": {
				"amount": 13, 
				"mineral": Enums.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value = round((u.value + 0.1) * 1.1 * 100) / 100
				u.cost.amount = pow(u.cost.amount, 1.35),
			"value": 0.5
		}),
		"crit_chance": Stat.new({
			"name": "crit_chance",
			"cost": {
				"amount": 999, 
				"mineral": Enums.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.cost.amount = pow(u.cost.amount, 1.35),
			"value": 0,
			"tooltip": "coming soon!"
		}),
		
		
		
		"lightning_length": Stat.new({
			"name": "lightning_length",
			"display_name": "length",
			"cost": {
				"amount": 25, 
				"mineral": Enums.Mineral.KYANITE
			},
			"upgrade_method": func(u): 
				u.value += 1
				u.cost.amount = pow(u.cost.amount, 1.3),
			"value": 1
		}),
		"lightning_damage": Stat.new({
			"name": "lightning_damage",
			"display_name": "damage",
			"cost": {
				"amount": 11, 
				"mineral": Enums.Mineral.KYANITE
			},
			"upgrade_method": func(u): 
				u.value += 0.2
				u.cost.amount *= pow(u.cost.amount, 1.1),
			"value": 0.8
		}),
		"lightning_chance": Stat.new({
			"name": "lightning_chance",
			"display_name": "chance",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.KYANITE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = Math.format_number_short(round(u.value * 1000) / 10.0) + "%",
			"value": 0
		}),
		
		"red_damage": Stat.new({
			"name": "red_damage",
			"display_name": "damage",
			"cost": {
				"amount": 8, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.05
				u.cost.amount *= 1.6,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 0.3,
			"tooltip": "damage multiplier on this colour"
		}),
		"red_portion": Stat.new({
			"name": "red_portion",
			"display_name": "portion",
			"cost": {
				"amount": 4, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 1.3,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"red_yield": Stat.new({
			"name": "red_yield",
			"display_name": "yield",
			"cost": {
				"amount": 7, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.05) * 1.1
				u.cost.amount *= 1.65,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 0.05,
			"tooltip": "olivine per click"
		}),
		
		"orange_damage": Stat.new({
			"name": "orange_damage",
			"display_name": "damage",
			"cost": {
				"amount": 9, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.15
				u.cost.amount *= 1.6,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 1,
			"tooltip": "damage multiplier on this colour"
		}),
		"orange_portion": Stat.new({
			"name": "orange_portion",
			"display_name": "portion",
			"cost": {
				"amount": 10, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 1.5,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"orange_yield": Stat.new({
			"name": "orange_yield",
			"display_name": "yield",
			"cost": {
				"amount": 5, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.7
				u.cost.amount *= 1.4,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 1,
			"tooltip": "olivine per click"
		}),
		
		"green_damage": Stat.new({
			"name": "green_damage",
			"display_name": "damage",
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.2
				u.cost.amount *= 1.8,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 2.5,
			"tooltip": "damage multiplier on this colour"
		}),
		"green_portion": Stat.new({
			"name": "green_portion",
			"display_name": "portion",
			"cost": {
				"amount": 14, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 1.5,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"green_yield": Stat.new({
			"name": "green_yield",
			"display_name": "yield",
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.4
				u.cost.amount *= 1.5,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 0.5,
			"tooltip": "olivine per click"
		}),
		
		"blue_damage": Stat.new({
			"name": "blue_damage",
			"display_name": "damage",
			"cost": {
				"amount": 42, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.5) * 1.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 5,
			"tooltip": "damage multiplier on this colour"
		}),
		"blue_portion": Stat.new({
			"name": "blue_portion",
			"display_name": "portion",
			"cost": {
				"amount": 28, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 1.8,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"blue_yield": Stat.new({
			"name": "blue_yield",
			"display_name": "yield",
			"cost": {
				"amount": 15, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.5) * 1.2
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 0.7,
			"tooltip": "olivine per click"
		}),
		
		"bar_replenish": Stat.new({
			"name": "bar_replenish",
			"display_name": "replenish speed",
			"cost": {
				"amount": 130, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.001) * 1.05
				u.cost.amount *= 3,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "% p/s",
			"value": 0.002,
			"tooltip": "bar replenish speed"
		}),
		"rock_boost": Stat.new({
			"name": "rock_boost",
			"display_name": "boost",
			"cost": {
				"amount": 240, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.01
				u.cost.amount *= 2.2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0.01,
			"tooltip": "replenish boost after breaking a rock"
		}),
		
		"boost_distance": Stat.new({
			"name": "boost_distance",
			"display_name": "distance",
			"max": 4,
			"cost": {
				"amount": 100,
				"mineral": Enums.Mineral.CORUNDUM
			},
			"upgrade_method": func(u):
				u.value += 1
				u.cost.amount *= 5,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 1,
			"tooltip": "maximum boost distance"
		}),
		"armour": Stat.new({
			"name": "armour",
			"max": 35,
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.CORUNDUM
			},
			"upgrade_method": func(u): 
				u.value -= 0.1
				u.cost.amount *= 1.2,
			"update_display": func (u):
				u.display_value = str(round(u.value * 100) / 100.0) + "s",
			"value": 4,
			"tooltip": "fuel lost per corundum hit"
		}),
		"boost_discount": Stat.new({
			"name": "boost_discount",
			"display_name": "discount",
			"max": 15,
			"cost": {
				"amount": 12, 
				"mineral": Enums.Mineral.CORUNDUM
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 100) * 1.2
				u.cost.amount *= 1.2,
			"update_display": func(u):
				u.display_value = str(round(u.value) / 100.0) + "%",
			"value": 0, # 1000 -> 10.00%, 100 -> 1%, 10 -> 0.1%
			"tooltip": "boost discount"
		}),
	}

func get_stat(name: String) -> Stat:
	return stats[name]

func get_stats() -> Dictionary:
	return stats

func get_portion(inp_colour: String) -> int:
	var colours: Array[String] = ["red", "orange", "green", "blue"]
	
	if !portions_changed: 
		return levels[colours.find(inp_colour)]
	
	levels = BASE_PORTIONS.duplicate()
	
	for i in colours.size():
		var colour = colours[i]
		for k in stats.get(colour + "_portion", {"level": 1}).level - 1:
			levels[i] += 4
			levels = levels.map(func (x): return x - 1)
	
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

func _add_mineral(mineral: Enums.Mineral, amount: float) -> void:
	if not has_discovered_mineral(mineral) and amount != 0:
		discover_mineral(mineral)
		mineral_discovered.emit(mineral)
	minerals[mineral] += amount

func get_mineral(mineral: Enums.Mineral) -> int:
	return int(minerals[mineral])

func upgrade_stat(name: String) -> void:
	if name.find("portion"): portions_changed = true
	stats[name].upgrade()
	stat_upgraded.emit(stats[name])

func has_discovered_state(state: Enums.State) -> bool:
	return discovered[Enums.EnumType.STATE].get(state, false)

func discover_state(state: Enums.State) -> void:
	discovered[Enums.EnumType.STATE][state] = true

func has_discovered_mineral(mineral: Enums.Mineral) -> bool:
	return discovered[Enums.EnumType.MINERAL].get(mineral, false)

func discover_mineral(mineral: Enums.Mineral) -> void:
	discovered[Enums.EnumType.MINERAL][mineral] = true

func can_upgrade_stat(name: String) -> bool:
	return not stats[name].is_max() and minerals[stats[name].cost.mineral] >= stats[name].cost.amount
