extends Button

const DAYS = [
	{}, # day 1 had no upgrades despite minerals
	{"minerals": {
		Enums.Mineral.AMETHYST: 18
	}},
	{"minerals": {
		Enums.Mineral.AMETHYST: 50
	}, "upgrades": ["fuel_capacity"]},
	{"minerals": {
		Enums.Mineral.AMETHYST: 37
	}, "upgrades": ["mineral_value", "thruster_speed"]},
	{"minerals": {
		Enums.Mineral.AMETHYST: 48
	}, "upgrades": ["fuel_capacity"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 6,
		Enums.Mineral.AMETHYST: 68
	}, "upgrades": ["fuel_capacity"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 6,
		Enums.Mineral.AMETHYST: 82
	}, "upgrades": ["mineral_value"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 17,
		Enums.Mineral.AMETHYST: 75,
		Enums.Mineral.OLIVINE: 6
	}, "upgrades": ["thruster_speed"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 4,
		Enums.Mineral.AMETHYST: 61,
		Enums.Mineral.OLIVINE: 14
	}, "upgrades": ["fuel_capacity", "hit_strength", "orange_yield"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 16,
		Enums.Mineral.AMETHYST: 37,
		Enums.Mineral.OLIVINE: 39
	}, "upgrades": ["orange_yield", "fuel_capacity"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 9,
		Enums.Mineral.AMETHYST: 65,
		Enums.Mineral.OLIVINE: 95
	}, "upgrades": ["orange_yield", "orange_yield", "hit_size"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 9,
		Enums.Mineral.AMETHYST: 81,
		Enums.Mineral.OLIVINE: 112
	}, "upgrades": ["blue_damage", "blue_yield", "blue_portion"]},
	{"minerals": {
		Enums.Mineral.TOPAZ: 13,
		Enums.Mineral.AMETHYST: 64,
		Enums.Mineral.OLIVINE: 101,
		Enums.Mineral.GOLD: 35
	}},
	{"minerals": {
		Enums.Mineral.TOPAZ: 57,
		Enums.Mineral.AMETHYST: 129,
		Enums.Mineral.OLIVINE: 50,
		Enums.Mineral.GOLD: 35
	}, "upgrades": ["fuel_capacity", "blue_damage"]},
]
@export var days: int


func _ready() -> void:
	text = "add " + str(days) + " day"

func _on_pressed() -> void:
	var new_day := GameManager.day + days
	if new_day >= DAYS.size(): return
	
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
