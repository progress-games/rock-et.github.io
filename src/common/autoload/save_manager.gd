extends Node


"""
manage the current save file.
create a new save file for a new game
trigger the save file when necessary
write the save file to disk when necessary
load a save file with a specified name for debugging purposes
"""

var loading_save: bool = true 

signal get_managed_states(arr: Array)
signal set_managed_states(arr: Dictionary)

static func store_save(save_name: String = "savegame") -> void:
	var minerals = GameManager.player.minerals.duplicate()
	var stats = GameManager.player.stats
	var items = GameManager.player.owned_items.duplicate(true)
	var exchange_rates = GameManager.exchange_rates.duplicate(true)
	
	var save = {
		"day": GameManager.day,
		"minerals": {},
		"stats": {},
		"items": {},
		"rates": {},
		"states": {},
		"discovered_minerals": []
	}
	for m in minerals.keys():
		save.minerals[Enums.Mineral.find_key(m)] = minerals[m]
	
	for stat in stats.keys():
		save.stats[stat] = stats[stat].level
	
	for item in items.keys():
		save.items[item] = items[item].level
	
	for rate in exchange_rates.keys():
		save.rates[Enums.Mineral.find_key(rate)] = {
			"past_rates": exchange_rates[rate].past_rates,
			"target": exchange_rates[rate].target.target
		}
	
	# collects all managed states, then extracts relevant data
	var managed_states: Array[ManagedState] = []
	SaveManager.get_managed_states.emit(managed_states)
	
	for state in managed_states:
		save.states[Enums.State.find_key(state.listening_state)] = {
			"revealed": state.revealed,
			"read_dialogue": state.read_dialogue,
			"discovered": GameManager.player.has_discovered_state(state.listening_state)
		}
	
	for mineral in Enums.Mineral.values():
		if GameManager.player.has_discovered_mineral(mineral):
			save.discovered_minerals.append(Enums.Mineral.find_key(mineral))
	
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save))
	save_file = null

static func load_save(save_name: String = "savegame") -> void:
	if !SaveManager.save_exists(save_name):
		return
	
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
	var data = JSON.parse_string(save_file.get_line())
	
	GameManager.day = data.day
	
	for m in data.minerals:
		GameManager.player.minerals[Enums.Mineral[m]] = data.minerals[m]
	
	for m in data.rates:
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates.clear()
		GameManager.exchange_rates[Enums.Mineral[m]].target.target = data.rates[m].target
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates = data.rates[m].past_rates
		GameManager.exchange_rates[Enums.Mineral[m]].refresh()
	
	GameManager.player.set_base_stats()
	for stat in data.stats.keys():
		for i in range(data.stats[stat] - 1):
			GameManager.player.upgrade_stat(stat)
	
	GameManager.player.owned_items.clear()
	for item in data.items.keys():
		GameManager.player.owned_items[item] = GameManager.player.all_items[item]
		for i in range(data.items[item] - 1):
			GameManager.player.owned_items[item].upgrade()
	
	for m in data.discovered_minerals:
		GameManager.player.discover_mineral(Enums.Mineral[m])
		GameManager.player.mineral_discovered.emit(Enums.Mineral[m])
	
	SaveManager.set_managed_states.emit(data.states)
	for state in data.states.keys():
		if data.states[state].discovered: 
			GameManager.player.discover_state(Enums.State[state])
	
	SaveManager.loading_save = false

static func save_exists(save_name: String = "savegame") -> bool:
	return FileAccess.file_exists("user://" + save_name + ".save")
