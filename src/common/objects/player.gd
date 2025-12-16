extends Object
class_name Player

var stats: Dictionary
var equipped_items: Dictionary[String, Item]
var owned_items: Dictionary[String, Item]
var all_items: Dictionary[String, Item]
var minerals: Dictionary
var hit_strength: String
var combo_amount: int
signal stat_upgraded(stat: Stat)
signal mineral_discovered(mineral: Enums.Mineral)

var discovered: Dictionary[Enums.EnumType, Dictionary] = {}
var portions_changed = true
var levels: Array
var olivine_fragments: float = 0

var scientist_disabled: bool = false

const BASE_PORTIONS: Array[int] = [10, 30, 50, 10]

func _init() -> void:
	set_base_stats()
	set_base_items()
	
	for enum_type in Enums.EnumType.keys():
		discovered[Enums.EnumType[enum_type]] = {}
	
	for name in Enums.Mineral.keys():
		minerals[Enums.Mineral[name]] = 0
	
	GameManager.add_mineral.connect(_add_mineral)
	
	GameManager.state_changed.connect(func (state): discover_state(state))

func set_base_stats() -> void:
	stats = {
		"fuel_capacity": Stat.new({
			"name": "fuel_capacity",
			"cost": {
				"amount": 10, 
				"mineral": Enums.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value = (u.value + 2) * 1.05
				u.cost.amount = (u.cost.amount + 8) * 1.15,
			"update_display": func (u):
				if u.value >= 60:
					u.display_value = str(round(u.value / 60))  + "m " + str(int(u.value) % 60) + "s"
				else:
					u.display_value = str(int(u.value) % 60) + "s",
			"value": 10,
			"tooltip": "fly for longer",
			"max": 20}),
		
		"thruster_speed": Stat.new({
			"name": "thruster_speed",
			"cost": {
				"amount": 13, 
				"mineral": Enums.Mineral.AMETHYST
			},
			"upgrade_method": func(u): 
				u.value += 1
				u.cost.amount = (u.cost.amount + 2) * 1.15, 
			"update_display": func (u):
				u.display_value = str(round(u.value * 10.0) / 10.0) + "px/s",
			"value": 0,
			"tooltip": "fly higher for better minerals",
			"max": 20}),
			
		"mineral_value": Stat.new({
			"name": "mineral_value",
			"cost": {
				"amount": 32, 
				"mineral": Enums.Mineral.AMETHYST
			}, 
			"upgrade_method": func(u): 
				u.value *= 1.25
				u.cost.amount = pow(u.cost.amount, 1.2), 
			"update_display": func(u):
				u.display_value = str(round(u.value * 100) / 100.0) + "x",
			"value": 1,
			"tooltip": "more minerals per asteroid",
			"max": 10}),

		"hit_size": Stat.new({
			"name": "hit_size",
			"cost": {
				"amount": 4, 
				"mineral": Enums.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.05) * 1.08
				u.cost.amount = (u.cost.amount + 5) * 1.4,
			"update_display": func(u):
				u.display_value = str(floor(u.value * 100) / 100) + "x",
			"value": 0.8
		}),
		"hit_strength": Stat.new({
			"name": "hit_strength",
			"cost": {
				"amount": 12, 
				"mineral": Enums.Mineral.TOPAZ
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.1) * 1.05
				u.cost.amount = (u.cost.amount + 6) * 1.35,
			"update_display": func(u):
				u.display_value = str(floor(u.value * 100) / 100) + "x",
			"value": 0.6
		}),
		"crit_chance": Stat.new({
			"name": "crit_chance",
			"cost": {
				"amount": 9999, 
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
			"max": 5,
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
				u.value = (u.value + 2) * 1.3
				u.cost.amount = pow(u.cost.amount, 1.3),
			"update_display": func(u):
				u.display_value = str(floor(u.value * 100) / 100) + "x",
			"value": 5
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
				u.value += 0.05
				u.cost.amount *= 2,
			"update_display": func(u):
				u.display_value = CustomMath.format_number_short(round(u.value * 1000) / 10.0) + "%",
			"value": 0
		}),
		
		"red_damage": Stat.new({
			"name": "red_damage",
			"display_name": "damage",
			"cost": {
				"amount": 3, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.05) * 1.05
				u.cost.amount *= 1.6,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "x",
			"value": 1,
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
			"level": 2,
			"tooltip": "portion of this colour"
		}),
		"red_yield": Stat.new({
			"name": "red_yield",
			"display_name": "yield",
			"cost": {
				"amount": 5, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = u.value + 0.05
				u.cost.amount *= 1.75,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 0.25,
			"tooltip": "olivine per click"
		}),
		
		"orange_damage": Stat.new({
			"name": "orange_damage",
			"display_name": "damage",
			"cost": {
				"amount": 14, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.3) * 1.1
				u.cost.amount *= 1.6,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "x",
			"value": 2,
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
			"max": 13,
			"cost": {
				"amount": 9, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.25) * 1.2
				u.cost.amount *= 1.5,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 1,
			"tooltip": "olivine per click"
		}),
		
		"green_damage": Stat.new({
			"name": "green_damage",
			"display_name": "damage",
			"cost": {
				"amount": 25, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.2) * 1.1
				u.cost.amount *= 1.8,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "x",
			"value": 4,
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
				"amount": 17, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.4) * 1.05
				u.cost.amount *= 1.3,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 1,
			"tooltip": "olivine per click"
		}),
		
		"blue_damage": Stat.new({
			"name": "blue_damage",
			"display_name": "damage",
			"cost": {
				"amount": 30, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.3) * 1.15
				u.cost.amount = (u.cost.amount + 50) * 1.8,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "x",
			"value": 8,
			"tooltip": "damage multiplier on this colour"
		}),
		"blue_portion": Stat.new({
			"name": "blue_portion",
			"display_name": "portion",
			"cost": {
				"amount": 34, 
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
				"amount": 27, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.2) * 1.15
				u.cost.amount = (u.cost.amount + 60) * 1.7,
			"update_display": func(u):
				u.display_value = str(round(u.value * 100.) / 100.0) + "/pc",
			"value": 1.4,
			"tooltip": "olivine per click"
		}),
		
		"bar_replenish": Stat.new({
			"name": "bar_replenish",
			"display_name": "replenish speed",
			"cost": {
				"amount": 500, 
				"mineral": Enums.Mineral.OLIVINE
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 0.0005) * 1.05
				u.cost.amount = (u.cost.amount + 100) * 1.5,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000 * 60) / 10.0) + "% p/s",
			"value": 0.0015,
			"tooltip": "bar replenish speed"
		}),
		"rock_boost": Stat.new({
			"name": "rock_boost",
			"display_name": "boost",
			"cost": {
				"amount": 250, 
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
				u.value += 0.1
				u.cost.amount *= 2.5,
			"update_display": func(u):
				u.display_value = str(round(u.value * 1000) / 10.0) + "%",
			"value": 0.1,
			"tooltip": "maximum boost distance"
		}),
		"armour": Stat.new({
			"name": "armour",
			"max": 6,
			"cost": {
				"amount": 6, 
				"mineral": Enums.Mineral.CORUNDUM
			},
			"upgrade_method": func(u): 
				u.value -= 0.3
				u.cost.amount *= 1.45,
			"update_display": func (u):
				u.display_value = str(round(u.value * 100) / 100.0) + "s",
			"value": 2.5,
			"tooltip": "fuel lost per corundum hit"
		}),
		"boost_discount": Stat.new({
			"name": "boost_discount",
			"display_name": "discount",
			"max": 8,
			"cost": {
				"amount": 12, 
				"mineral": Enums.Mineral.CORUNDUM
			},
			"upgrade_method": func(u): 
				u.value = (u.value + 500) * 1.1
				u.cost.amount *= 1.2,
			"update_display": func(u):
				u.display_value = str(round(u.value) / 100.0) + "%",
			"value": 0, # 1000 -> 10.00%, 100 -> 1%, 10 -> 0.1%
			"tooltip": "boost discount"
		}),
	}

func set_base_items() -> void:
	all_items = {
		"pickaxe": Item.new({
		"name": "pickaxe",
		"description": "[gold_chance] chance to drop [gold_amount] gold",
		"values": {
			"gold_chance": {
				"value": 0.05,
				"type": "percentage",
				"improves": true,
				"upgrade": func (x): return x + 0.08
				}, 
			"gold_amount": {
				"value": 2,
				"type": "none",
				"improves": true,
				"upgrade": func (x): return x * 1.3
				}
			},
		"cost": 25,
		"cost_scaling": 1.2
		}),
		
		"boxing_gloves": Item.new({
			"name": "boxing_gloves",
			"description": "do [damage_multiplier] damage for the first [hits] hits",
			"cost": 18,
			"cost_scaling": 1.4,
			"values": {
				"damage_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 3.0,
					"upgrade": func (x): return x * 1.2
				},
				"hits": {
					"type": "value",
					"improves": true,
					"value": 8,
					"upgrade": func (x): return x + 3
				}
			}
		}),
		
		"combo": Item.new({
			"name": "combo",
			"description": "break asteroids for [damage_multiplier] damage, stacks [max_combo] times",
			"cost": 21,
			"cost_scaling": 1.1,
			"values": {
				"damage_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 1.2,
					"upgrade": func (x): return x * 1.4
				},
				"max_combo": {
					"type": "none",
					"improves": true,
					"value": 3,
					"upgrade": func (x): return x + 1
				}
			}
		}),
		
		"stopwatch": Item.new({
			"name": "stopwatch",
			"description": "asteroids drop [mineral_multiplier] minerals, but they fade [fade_speed] faster",
			"cost": 17,
			"cost_scaling": 1.7,
			"values": {
				"mineral_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 1.3,
					"upgrade": func (x): return x + 0.3
				},
				"fade_speed": {
					"type": "multiplier",
					"improves": false,
					"value": 2,
					"upgrade": func (x): return x + 0.5
				}
			}
		}),
		
		"harvesting": Item.new({
			"name": "harvesting",
			"description": "minerals leftover are collected with [mineral_multiplier] value",
			"cost": 27,
			"cost_scaling": 1.25,
			"values": {
				"mineral_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 1.3,
					"upgrade": func (x): return x + 0.15
				}
			}
		}),
		
		"target_practice": Item.new({
			"name": "target_practice",
			"description": "rocks move [erratic_movement] more erratically but give [mineral_multiplier] minerals",
			"cost": 16,
			"cost_scaling": 1.35,
			"values": {
				"mineral_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 1.3,
					"upgrade": func (x): return x + 0.2
				},
				"erratic_movement": {
					"type": "multiplier",
					"improves": false,
					"value": 1.1,
					"upgrade": func (x): return x + 0.2
				}
			}
		}),
		
		"binoculars": Item.new({
			"name": "binoculars",
			"description": "[asteroid_spawn] more asteroids",
			"cost": 31,
			"cost_scaling": 1.6,
			"values": {
				"asteroid_spawn": {
					"type": "multiplier",
					"improves": true,
					"value": 1.3,
					"upgrade": func (x): return x + 0.15
				}
			}
		})
	}
	
	# for item in all_items.keys(): equipped_items[item] = all_items[item]

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
	return not stats[name].is_max() and can_afford(stats[name].cost.amount, stats[name].cost.mineral)

func can_afford(price: float, mineral: Enums.Mineral) -> bool:
	return floor(price) <= floor(minerals[mineral])

func has_equipped(item_name: String) -> bool:
	return equipped_items.has(item_name)

func equip_item(item_name: String) -> void:
	equipped_items.set(item_name, owned_items[item_name])

func unequip_item(item_name: String) -> void:
	equipped_items.erase(item_name)
