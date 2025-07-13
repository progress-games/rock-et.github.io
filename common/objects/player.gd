extends Object
class_name Player

var stats: Dictionary
var minerals: Dictionary
signal stat_upgraded(stat: Stat)

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
			"value": 0.4
		}),
		
		"lightning_length": Stat.new({
			"name": "length",
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
			"name": "damage",
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
			"name": "chance",
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
		})
	}

func get_stat(name: String) -> Stat:
	return stats[name]

func get_stats() -> Dictionary:
	return stats

func _add_mineral(mineral: GameManager.Mineral, amount: float) -> void:
	minerals[mineral] += amount

func get_mineral(mineral: GameManager.Mineral) -> int:
	return int(minerals[mineral])

func upgrade_stat(name: String) -> void:
	stats[name].upgrade()
	stat_upgraded.emit(stats[name])

func can_upgrade_stat(name: String) -> bool:
	return not stats[name].is_max() and minerals[stats[name].cost.mineral] >= stats[name].cost.amount
