extends Object
class_name Player

var stats: Dictionary

func _init() -> void:
	set_base_stats()

func set_base_stats() -> void:
	stats = {
		"spawn rate": Stat.new({
			"name": "spawn rate",
			"level": 0, 
			"cost": 10, 
			"method": func(u): 
				u.value -= 0.1
				u.cost *= 1.2, 
			"value": 3})
	}

func get_stat(name: String) -> Stat:
	return stats[name]

func get_stats() -> Dictionary:
	return stats
