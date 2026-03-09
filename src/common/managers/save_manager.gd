extends Node


"""
manage the current save file.
create a new save file for a new game
trigger the save file when necessary
write the save file to disk when necessary
load a save file with a specified name for debugging purposes
"""

const CURRENT_VERSION := "1.0"

var loading_save: bool = true 

signal get_managed_states(arr: Array)
signal set_managed_states(arr: Dictionary)

signal get_unlocked_nodes(dict: Dictionary)
signal set_unlocked_nodes(dict: Dictionary)

func store_save(save_name: String = "savegame") -> void:
	var minerals = GameManager.player.minerals.duplicate()
	var stats = StatManager.stats
	var items = GameManager.player.owned_items.duplicate(true)
	var exchange_rates = GameManager.exchange_rates.duplicate(true)
	
	var save = {
		"day": GameManager.day,
		"planet": GameManager.planet,
		"minerals": {},
		"stats": {},
		"items": {},
		"rates": {},
		"states": {},
		"discovered_minerals": [],
		"skill_nodes": {},
		"version": CURRENT_VERSION
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
	
	var skill_nodes: Dictionary = {}
	SaveManager.get_unlocked_nodes.emit(skill_nodes)
	
	save.skill_nodes = skill_nodes
	
	for mineral in Enums.Mineral.values():
		if GameManager.player.has_discovered_mineral(mineral):
			save.discovered_minerals.append(Enums.Mineral.find_key(mineral))
	
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.WRITE)
	save_file.store_line(JSON.stringify(save))
	save_file = null

func load_save(save_name: String = "savegame") -> void:
	var save_file = FileAccess.open("user://" + save_name + ".save", FileAccess.READ)
	var data = JSON.parse_string(save_file.get_line())
	
	# var data = JSON.parse_string("""{"day":44,"discovered_minerals":["AMETHYST","TOPAZ","KYANITE","OLIVINE","CORUNDUM","GOLD","QUARTZ"],"items":{"binoculars":3,"combo":4,"harvesting":3,"pickaxe":6,"stopwatch":2,"target_practice":4},"minerals":{"AMETHYST":7845.0,"CORUNDUM":570.310610633817,"GOLD":867.025821981465,"KYANITE":735.0,"OLIVINE":7310.0,"QUARTZ":0.0,"TOPAZ":5036.0,"TUGTUPITE":0.0},"planet":0,"rates":{"AMETHYST":{"past_rates":[31.0, 36.0, 40.0, 42.0, 48.0, 55.0, 64.0, 40.0, 28.0, 19.0],"target":10.0},"CORUNDUM":{"past_rates":[48.4156282068691,49.748736439568,48.6896703546482,49.8902816280461,43.5590262080935,43.0902131305096,48.3808333239448,44.664399993321,49.1129232512644,48.2803016948696],"target":47.0064399433141},"KYANITE":{"past_rates":[67.2884392545412,64.613041736225,55.4109230411767,54.6582572815623,66.5352950880226,54.5647922173952,57.7878025586204,55.4474977209896,55.0698018807145,57.143023376456],"target":63.7691287997866},"OLIVINE":{"past_rates":[1.0,22.8729567754557,34.0962148090573,1.0,1.0,9.66859053335721,1.0,18.8222892772316,1.0,61.0957368286355],"target":62.8202332594523},"TOPAZ":{"past_rates":[37.5631909897167,39.4539578635863,23.2945392475603,21.5329950487429,14.6436748838073,29.3308499332867,20.3471334248617,16.1999648127112,23.5998941066194,19.6716173420824],"target":18.740424535789}},"states":{"BLEEG":{"discovered":true,"read_dialogue":true,"revealed":true},"CLICKY":{"discovered":true,"read_dialogue":true,"revealed":true},"EXCHANGE":{"discovered":true,"read_dialogue":true,"revealed":true},"FACTORY":{"discovered":true,"read_dialogue":true,"revealed":true},"GARAGE":{"discovered":true,"read_dialogue":true,"revealed":true},"LAUNCH":{"discovered":true,"read_dialogue":true,"revealed":true},"MERCHANT":{"discovered":true,"read_dialogue":true,"revealed":true},"SCIENTIST":{"discovered":true,"read_dialogue":true,"revealed":true},"SETTINGS":{"discovered":true,"read_dialogue":true,"revealed":true},"SHIKOBA":{"discovered":false,"read_dialogue":true,"revealed":true}},"stats":{"armour":6,"bar_replenish":3,"blue_damage":5,"blue_portion":6,"blue_yield":4,"boost_discount":8,"boost_distance":4,"crit_chance":1,"damage_boost":1,"fuel_boost":1,"fuel_capacity":20,"green_damage":4,"green_portion":2,"green_yield":6,"hit_size":13,"hit_strength":13,"kruos_fuel_capacity":1,"kruos_thruster_speed":1,"lightning_chance":7,"lightning_damage":5,"lightning_length":2,"mineral_value":6,"more_minerals":1,"orange_damage":6,"orange_portion":2,"orange_yield":10,"powerup_duration":1,"powerup_spawn_rate":1,"powerup_ultra_chance":1,"red_damage":1,"red_portion":55,"red_yield":1,"rock_boost":3,"speed_boost":1,"thruster_speed":20,"unlocked_powerups":1},"version":"1.0"""
	
	if !data.get("version") or data.version != CURRENT_VERSION:
		return
	
	GameManager.day = data.day
	
	for m in data.minerals:
		GameManager.player.minerals[Enums.Mineral[m]] = data.minerals[m]
	
	for m in data.rates:
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates.clear()
		GameManager.exchange_rates[Enums.Mineral[m]].target.target = data.rates[m].target
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates = data.rates[m].past_rates
		GameManager.exchange_rates[Enums.Mineral[m]].refresh()
	
	StatManager._set_base_stats()
	for stat in data.stats.keys():
		for i in range(data.stats[stat] - 1):
			StatManager.upgrade_stat(stat)
	
	GameManager.player.owned_items.clear()
	for item in data.items.keys():
		GameManager.player.all_items[item].level = 1
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
		if data.states[state].read_dialogue:
			GameManager.read_state_dialogue.emit(Enums.State[state])
	
	SaveManager.set_unlocked_nodes.emit(data.skill_nodes)
	
	GameManager.planet_changed.emit(int(data.planet))
	
	SaveManager.loading_save = false

func save_exists(save_name: String = "savegame") -> bool:
	return FileAccess.file_exists("user://" + save_name + ".save")

func load_if_exists(save_name: String = "savegame") -> void:
	if save_exists(save_name): 
		load_save(save_name)
