extends Object
class_name Player

var stats: Dictionary
var minerals: Dictionary
var hit_strength: String
signal stat_upgraded(stat: Stat)
signal mineral_discovered(mineral: GameManager.Mineral)

var discovered_minerals: Dictionary[GameManager.Mineral, bool] = {}
var portions_changed = true
var levels: Array
var olivine_fragments: float = 0;

const BASE_PORTIONS: Array[int] = [20, 25, 45, 10]

func _init() -> void:
	set_base_stats()
	GameManager.add_mineral.connect(_add_mineral)
	
	for name in GameManager.Mineral.keys():
		minerals[GameManager.Mineral[name]] = 0

func set_base_stats() -> void:
	stats = {
		"fuel_capacity": Stat.new({
			"name": "fuel_capacity",
			"cost": {
				"amount": 12, 
				"mineral": GameManager.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value += 3
				u.cost.amount *= 1.3,
			"update_display": func (u):
				if u.value >= 60:
					u.display_value = str(u.value / 60) + "m " + str(u.value % 60) + "s"
				else:
					u.display_value = str(u.value % 60) + "s",
			"value": 10,
			"tooltip": "fly for longer",
			"max": 10}),
		
		"thruster_speed": Stat.new({
			"name": "thruster_speed",
			"cost": {
				"amount": 18, 
				"mineral": GameManager.Mineral.AMETHYST
			},
			"upgrade_method": func(u): 
				u.value += 2
				u.cost.amount = pow(u.cost.amount, 1.1), 
			"update_display": func (u):
				u.display_value = str(u.value) + "px/s",
			"value": 0,
			"tooltip": "fly higher for better minerals",
			"max": 10}),
			
		"mineral_value": Stat.new({
			"name": "mineral_value",
			"cost": {
				"amount": 30, 
				"mineral": GameManager.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value *= 1.2
				u.cost.amount = pow(u.cost.amount, 1.2), 
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 1000.0) + "x",
			"value": 1,
			"tooltip": "value of each mineral",
			"max": 10}),

		"hit_size": Stat.new({
			"name": "hit_size",
			"cost": {
				"amount": 7, 
				"mineral": GameManager.Mineral.TOPAZ
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
				"amount": 12, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.3,
			"value": 0.5
		}),
		"armour": Stat.new({
			"name": "armour",
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.2,
			"value": 0.4,
			"tooltip": "Coming soon!"
		}),
		
		"lightning_length": Stat.new({
			"name": "lightning_length",
			"display_name": "length",
			"cost": {
				"amount": 25, 
				"mineral": GameManager.Mineral.KYANITE
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
				"mineral": GameManager.Mineral.KYANITE
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
				"mineral": GameManager.Mineral.KYANITE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0
		}),
		
		"red_damage": Stat.new({
			"name": "red_damage",
			"display_name": "damage",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 0.2,
			"tooltip": "damage multiplier on this colour"
		}),
		"red_portion": Stat.new({
			"name": "red_portion",
			"display_name": "portion",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"red_yield": Stat.new({
			"name": "red_yield",
			"display_name": "yield",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "/pc",
			"value": 0.01,
			"tooltip": "olivine per click"
		}),
		
		"orange_damage": Stat.new({
			"name": "orange_damage",
			"display_name": "damage",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 0.4,
			"tooltip": "damage multiplier on this colour"
		}),
		"orange_portion": Stat.new({
			"name": "orange_portion",
			"display_name": "portion",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"orange_yield": Stat.new({
			"name": "orange_yield",
			"display_name": "yield",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0.01,
			"tooltip": "olivine per click"
		}),
		
		"green_damage": Stat.new({
			"name": "green_damage",
			"display_name": "damage",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 1,
			"tooltip": "damage multiplier on this colour"
		}),
		"green_portion": Stat.new({
			"name": "green_portion",
			"display_name": "portion",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"green_yield": Stat.new({
			"name": "green_yield",
			"display_name": "yield",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0.01,
			"tooltip": "olivine per click"
		}),
		
		"blue_damage": Stat.new({
			"name": "blue_damage",
			"display_name": "damage",
			"max": 10,
			"cost": {
				"amount": 12, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "x",
			"value": 2,
			"tooltip": "damage multiplier on this colour"
		}),
		"blue_portion": Stat.new({
			"name": "blue_portion",
			"display_name": "portion",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(u.value) + "%",
			"value": 1,
			"tooltip": "portion of this colour"
		}),
		"blue_yield": Stat.new({
			"name": "blue_yield",
			"display_name": "yield",
			"max": 10,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value += 0.1
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0.01,
			"tooltip": "olivine per click"
		})
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

func _add_mineral(mineral: GameManager.Mineral, amount: float) -> void:
	if not has_discovered(mineral):
		discover(mineral)
		mineral_discovered.emit(mineral)
	minerals[mineral] += amount

func get_mineral(mineral: GameManager.Mineral) -> int:
	return int(minerals[mineral])

func upgrade_stat(name: String) -> void:
	if name.find("portion"): portions_changed = true
	stats[name].upgrade()
	stat_upgraded.emit(stats[name])

func has_discovered(mineral: GameManager.Mineral) -> bool:
	return discovered_minerals.get(mineral, false)

func discover(mineral: GameManager.Mineral) -> void:
	discovered_minerals[mineral] = true

func can_upgrade_stat(name: String) -> bool:
	return not stats[name].is_max() and minerals[stats[name].cost.mineral] >= stats[name].cost.amount
