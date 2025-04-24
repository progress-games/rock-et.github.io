extends Object
class_name Player

var stats: Dictionary
var minerals: Dictionary

func _init() -> void:
	set_base_stats()
	GameManager.add_mineral.connect(_add_mineral)
	
	for name in GameManager.Mineral.keys():
		minerals[GameManager.Mineral[name]] = 0

func set_base_stats() -> void:
	stats = {
		"thruster_speed": Stat.new({
			"name": "thruster speed",
			"level": 0,
			"cost": 10,
			"method": func(u): 
				u.value += 1
				u.cost = pow(u.cost, 1.1), 
			"value": 0
		}),
		"spawn_rate": Stat.new({
			"name": "spawn rate",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value -= 0.1
				u.cost *= 1.2, 
			"value": 3}),
		"mineral_value": Stat.new({
			"name": "mineral value",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value -= 0.1
				u.cost *= 1.2, 
			"value": 3}),
		"fuel_capacity": Stat.new({
			"name": "fuel capacity",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value += 1
				u.cost *= 1.2, 
			"value": 7}),
		"rock_level": Stat.new({
			"name": "rock level",
			"level": 0,
			"cost": 10,
			"method": func(u): 
				u.value.m += 0.8
				u.value.s += 0.5
				u.cost *= 1.3,
			"value": {
				"m": 1,
				"s": 0.5,
			}})
	}

func get_stat(name: String) -> Stat:
	return stats[name]

func get_stats() -> Dictionary:
	return stats

func _add_mineral(mineral: GameManager.Mineral, amount: int) -> void:
	minerals[mineral] += amount

func get_mineral(mineral: GameManager.Mineral) -> int:
	return minerals[mineral]

func upgrade_stat(name: String) -> void:
	stats[name].upgrade()
