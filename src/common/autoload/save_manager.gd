extends Node

"""
manage the current save file.
create a new save file for a new game
trigger the save file when necessary
write the save file to disk when necessary
load a save file with a specified name for debugging purposes
"""

func _ready() -> void:
	GameManager.day_changed.connect(func (d): if d != 0: store_save())

func store_save() -> void:
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
		"states": []
	}
	for m in minerals.keys():
		save.minerals[Enums.Mineral.find_key(m)] = minerals[m]
	
	for stat in stats.keys():
		save.stats[stat] = stats[stat].level
	
	for item in items.keys():
		save.items[item] = items[item].level
	
	for rate in exchange_rates.keys():
		save.rates[Enums.Mineral.find_key(rate)] = exchange_rates[rate].past_rates
	
	for state in Enums.State.keys():
		if GameManager.player.has_discovered_state(Enums.State[state]):
			save.states.append(state)
	
	var save_file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save))
	save_file = null
	
	load_save()

func load_save(save_name: String = "savegame") -> void:
	if not FileAccess.file_exists("user://" + save_name + ".save"):
		return
	
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
	var json = JSON.new()
	json.parse(save_file.get_line())
	
	GameManager.day = json.data.day
	
	for m in json.data.minerals:
		GameManager.player.minerals[Enums.Mineral[m]] = json.data.minerals[m]
	
	for m in json.data.rates:
		var t = GameManager.exchange_rates[Enums.Mineral[m]]
		var t2 = json.data.rates[m]
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates = json.data.rates[m]
	
	for stat in json.data.stats.keys():
		for i in range(json.data.stats[stat] - 1):
			GameManager.player.upgrade_stat(stat)
	
	for item in json.data.items.keys():
		GameManager.player.owned_items[item] = GameManager.player.all_items[item]
		for i in range(json.data.items[item] - 1):
			GameManager.player.owned_items[item].upgrade()
