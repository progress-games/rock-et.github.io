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
			"name": "fuel capacity",
			"level": 1, 
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.AMETHYST
			}, 
			"method": func(u): 
				u.value += 3
				u.cost.amount *= 1.2, 
			"value": 10}),
		"thruster_speed": Stat.new({
			"name": "thruster speed",
			"level": 1,
			"cost": {
				"amount": 10, 
				"mineral": GameManager.Mineral.AMETHYST
			},
			"method": func(u): 
				u.value += 2
				u.cost.amount = pow(u.cost.amount, 1.1), 
			"value": 0}),
		"mineral_value": Stat.new({
			"name": "mineral value",
			"level": 1, 
			"cost": {
				"amount": 12, 
				"mineral": GameManager.Mineral.AMETHYST
			}, 
			"method": func(u): 
				u.value *= 1.1
				u.cost.amount = pow(u.cost.amount, 1.2), 
			"value": 1}),

		"hit_size": Stat.new({
			"name": "hit size",
			"level": 1,
			"cost": {
				"amount": 7, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.2
				u.cost.amount = pow(u.cost.amount, 1.2),
			"value": 0.4
		}),
		"hit_strength": Stat.new({
			"name": "hit strength",
			"level": 1,
			"cost": {
				"amount": 3, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.3,
			"value": 0.5
		}),
		"armour": Stat.new({
			"name": "armour",
			"level": 1,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.2,
			"value": 0.4
		}),
		
		"lightning_length": Stat.new({
			"name": "length",
			"level": 1,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.2,
			"value": 0.4
		}),
		"lightning_damage": Stat.new({
			"name": "damage",
			"level": 1,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.2,
			"value": 0.4
		}),
		"lightning_range": Stat.new({
			"name": "range",
			"level": 1,
			"cost": {
				"amount": 6, 
				"mineral": GameManager.Mineral.TOPAZ
			},
			"method": func(u): 
				u.value += 0.1
				u.cost.amount *= 1.2,
			"value": 0.4
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
	stats[name].level += 1
	stat_upgraded.emit(stats[name])

func can_upgrade_stat(name: String) -> bool:
	return minerals[stats[name].cost.mineral] >= stats[name].cost.amount
