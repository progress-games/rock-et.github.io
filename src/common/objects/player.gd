extends Object
class_name Player

var equipped_items: Dictionary[String, Item]
var owned_items: Dictionary[String, Item]
var all_items: Dictionary[String, Item]

var all_potions: Dictionary[String, Potion]
var owned_potions: Array[String]
var equipped_potions: Array[String]

var minerals: Dictionary
var hit_strength: String
var combo_amount: int
signal mineral_discovered(mineral: Enums.Mineral)

var discovered: Dictionary[Enums.EnumType, Dictionary] = {}
var portions_changed = true
var levels: Array
var olivine_fragments: float = 0

var scientist_disabled: bool = false


func _init() -> void:
	set_base_items()
	set_base_potions()
	reset_discovered()
	
	for name in Enums.Mineral.keys():
		minerals[Enums.Mineral[name]] = 0
	
	GameManager.add_mineral.connect(_add_mineral)
	
	GameManager.state_changed.connect(func (state): discover_state(state))

func reset_discovered() -> void:
	for enum_type in Enums.EnumType.keys():
		discovered[Enums.EnumType[enum_type]] = {}

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
		"cost": 44,
		"cost_scaling": 1.2
		}),
		
		"boxing_gloves": Item.new({
			"name": "boxing_gloves",
			"description": "do [damage_multiplier] damage for the first [hits] hits",
			"cost": 29,
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
			"cost": 35,
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
			"cost": 61,
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
			"cost": 44,
			"cost_scaling": 1.25,
			"values": {
				"mineral_multiplier": {
					"type": "multiplier",
					"improves": true,
					"value": 1.5,
					"upgrade": func (x): return x + 0.15
				}
			}
		}),
		
		"target_practice": Item.new({
			"name": "target_practice",
			"description": "rocks move [erratic_movement] more erratically but give [mineral_multiplier] minerals",
			"cost": 54,
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
			"cost": 30,
			"cost_scaling": 1.6,
			"values": {
				"asteroid_spawn": {
					"type": "multiplier",
					"improves": true,
					"value": 1.3,
					"upgrade": func (x): return x + 0.1
				}
			}
		})
	}
	
	#for item in all_items.keys(): equipped_items[item] = all_items[item]

func set_base_potions() -> void:
	all_potions = {
		"asteroid_storm": Potion.new({
			"name": "asteroid_storm",
			"description": "spawns 100 asteroids",
			"cost": 189
		}),
		"gatling_click": Potion.new({
			"name": "gatling_click",
			"description": "autoclicks 50 times a second",
			"cost": 241
		}),
		"gold_rush": Potion.new({
			"name": "gold_rush",
			"description": "all minerals are replaced with gold",
			"cost": 361
		}),
		#"mega_rock": Potion.new({
			#"name": "mega_rock",
			#"description": "spawns a mega rock",
			#"cost": 50
		#}),
		#"mirror_image": Potion.new({
			#"name": "mirror_image",
			#"description": "spawn a mirror image cursor",
			#"cost": 50
		#}),
		"supernova": Potion.new({
			"name": "supernova",
			"description": "spawns a black hole",
			"cost": 68
		}),
		"supersize": Potion.new({
			"name": "supersize",
			"description": "3x hitbox size",
			"cost": 99
		}),
		"vacuum": Potion.new({
			"name": "vacuum",
			"description": "insta-collect all minerals for 10x value",
			"cost": 221
		}),
	}

func _add_mineral(mineral: Enums.Mineral, amount: float) -> void:
	if not has_discovered_mineral(mineral) and amount != 0:
		discover_mineral(mineral)
		mineral_discovered.emit(mineral)
	minerals[mineral] += amount

func get_mineral(mineral: Enums.Mineral) -> int:
	return int(minerals[mineral])

func has_discovered_state(state: Enums.State) -> bool:
	return discovered[Enums.EnumType.STATE].get(state, false)

func discover_state(state: Enums.State) -> void:
	discovered[Enums.EnumType.STATE][state] = true

func has_discovered_mineral(mineral: Enums.Mineral) -> bool:
	return discovered[Enums.EnumType.MINERAL].get(mineral, false)

func discover_mineral(mineral: Enums.Mineral) -> void:
	discovered[Enums.EnumType.MINERAL][mineral] = true

func can_afford(price: float, mineral: Enums.Mineral) -> bool:
	return floor(price) <= floor(minerals[mineral])

func has_equipped(item_name: String) -> bool:
	return equipped_items.has(item_name)

func equip_item(item_name: String) -> void:
	equipped_items.set(item_name, owned_items[item_name])

func unequip_item(item_name: String) -> void:
	equipped_items.erase(item_name)
