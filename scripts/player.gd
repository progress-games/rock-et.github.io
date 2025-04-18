extends Object
class_name Player

var stats: Dictionary
var points = 0

func _init() -> void:
	set_base_stats()
	GameManager.add_point.connect(_add_point)

func set_base_stats() -> void:
	stats = {
		"spawn_rate": Stat.new({
			"name": "spawn rate",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value -= 0.1
				u.cost *= 1.2, 
			"value": 3}),
		"duration": Stat.new({
			"name": "duration",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value += 1
				u.cost *= 1.2, 
			"value": 20}),
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

func _add_point(amount: int) -> void:
	points += amount
