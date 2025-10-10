extends Button

@export var days: int

const DAYS = [
	{},
	{"minerals": {Enums.Mineral.AMETHYST: 6}, "upgrades": ["fuel_capacity"]},
	{"minerals": {Enums.Mineral.AMETHYST: 10}, "upgrades": ["thruster_speed"]},
	{"minerals": {Enums.Mineral.AMETHYST: 26}},
	{"minerals": {Enums.Mineral.AMETHYST: 16}, "upgrades": ["mineral_value"]},
	{"minerals": {Enums.Mineral.AMETHYST: 8}, "upgrades": ["fuel_capacity"]},
	{"minerals": {Enums.Mineral.AMETHYST: 25}},
	{"minerals": {Enums.Mineral.AMETHYST: 23}, "upgrades": ["fuel_capacity"]},
	{"minerals": {Enums.Mineral.AMETHYST: 24}, "upgrades": ["thruster_speed"]},
	{"minerals": {Enums.Mineral.AMETHYST: 7}, "upgrades": ["fuel_capacity"]},
	{"minerals": {Enums.Mineral.AMETHYST: 52}},
	{"minerals": {Enums.Mineral.AMETHYST: 31, Enums.Mineral.TOPAZ: 4}, "upgrades": ["mineral_value"]},
	{"minerals": {Enums.Mineral.AMETHYST: 33, Enums.Mineral.TOPAZ: 4}, "upgrades": ["fuel_capacity"]},
	{"minerals": {Enums.Mineral.AMETHYST: 71, Enums.Mineral.TOPAZ: 1}, "upgrades": ["hit_strength", "hit_size", "hit_size"]},
	{"minerals": {Enums.Mineral.AMETHYST: 51}},
	{"minerals": {Enums.Mineral.AMETHYST: 41, Enums.Mineral.TOPAZ: 2}, "upgrades": ["fuel_capacity", "hit_strength"]},
	{"minerals": {Enums.Mineral.AMETHYST: 26, Enums.Mineral.TOPAZ: 2, Enums.Mineral.OLIVINE: 7}, "upgrades": ["fuel_capacity", "hit_size", "orange_yield", "orange_yield"]},
	{"minerals": {Enums.Mineral.AMETHYST: 50, Enums.Mineral.TOPAZ: 2, Enums.Mineral.OLIVINE: 29}, "upgrades": ["orange_yield", "orange_yield", "orange_yield", "orange_yield"]},
	{"minerals": {Enums.Mineral.AMETHYST: 81, Enums.Mineral.TOPAZ: 2, Enums.Mineral.OLIVINE: 22}, "upgrades": ["blue_damage", "blue_damage", "blue_yield", "blue_yield", "blue_yield"]},
	{"minerals": {Enums.Mineral.AMETHYST: 14, Enums.Mineral.TOPAZ: 54, Enums.Mineral.OLIVINE: 28}, "upgrades": ["hit_size", "bar_replenish", "mineral_value"]},
	{"minerals": {Enums.Mineral.AMETHYST: 49, Enums.Mineral.TOPAZ: 76, Enums.Mineral.OLIVINE: 133}, "upgrades": ["fuel_capacity", "blue_damage", "hit_strength"]},
]

func _ready() -> void:
	text = "add " + str(days) + " day"


func _on_pressed() -> void:
	var new_day := GameManager.day + days
	if new_day > DAYS.size(): return
	
	var minerals = DAYS[new_day].get("minerals", {})
	
	for mineral in minerals.keys():
		GameManager.player.minerals[mineral] = 0
		GameManager.add_mineral.emit(mineral, minerals[mineral])
	
	for day in range(days):
		var upgrades = DAYS[GameManager.day + day].get("upgrades", {})
		for upgrade in upgrades:
			GameManager.player.upgrade_stat(upgrade)
		
		GameManager.day_changed.emit(GameManager.day + day + 1)
	
	GameManager.state_changed.emit(GameManager.state)
