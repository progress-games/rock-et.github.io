extends Resource
class_name SaveData

@export var version := 1.1

"""
SAVE DETAILS:

day
game version
stats
items
potions
mineral amounts
current planet
settings
skill nodes
discovered minerals
discovered states
dialogue progress
wheel state
current drink modifiers
rng seed
owned drones
drone grid
tutorial progress
days taken
merchant day

states:
	discovered, revealed, dialogue progress
"""

@export var day: int

@export var tutorial_progress: Array[Enums.Tutorial]

@export var next_merchant_day: int = -1

@export var endless_mode: bool

@export var rng_seed: int

@export var planet: Enums.Planet

# "stat_name": level
@export var stat_levels: Dictionary[String, int]

# State: [discovered, revealed, dialogue_progress]
@export var states: Dictionary[Enums.State, StateData]

@export var mineral_amounts: Dictionary[int, float]
@export var discovered_minerals: Array[Enums.Mineral]

@export var owned_items: Dictionary[String, int]

@export var owned_potions: Array[String]

@export var wheel_upgrades: Array[int]

@export var nodes: Dictionary

@export var active_drink_modifiers: Array[int]

#var states: Array
#var stats: Dictionary
#
#func _init() -> void:
	#StatManager.stat_upgraded.connect(update_stat)
#
#func update_stat(stat_name: String) -> void:
	#stats.set(stat_name, StatManager.get_stat(stat_name).level)
#
#func save_stats() -> void:
	#stats.clear()
	#for stat in StatManager.stats.keys(): # Dictionary[String, Stat]
		#stats.set(stat, StatManager.stats[stat].level)
