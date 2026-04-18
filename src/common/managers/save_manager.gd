extends Node


"""
manage the current save file.
create a new save file for a new game
trigger the save file when necessary
write the save file to disk when necessary
load a save file with a specified name for debugging purposes
"""

const CURRENT_VERSION := "1.1"

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
	var settings = Settings.values
	
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
		"settings": {},
		"version": CURRENT_VERSION
	}
	for s in settings.keys():
		save.settings[Settings.SettingType.find_key(s)] = settings[s]
	
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
		save.states[Enums.State.find_key(state.state)] = {
			"revealed": state.revealed,
			"read_dialogue": state.read_dialogue,
			"discovered": GameManager.player.has_discovered_state(state.state)
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
	
	#var data = JSON.parse_string("""
		#{"day":44,"discovered_minerals":["AMETHYST","TOPAZ","KYANITE","OLIVINE","CORUNDUM","GOLD"],"items":{},"minerals":{"AMETHYST":7845.0,"CORUNDUM":570.310610633817,"GOLD":867.025821981465,"KYANITE":735.0,"OLIVINE":7310.0,"QUARTZ":0.0,"TOPAZ":5036.0,"TUGTUPITE":0.0},"planet":1,"rates":{"AMETHYST":{"past_rates":[3.49843037462065,11.8111224578674,4.46586014115017,14.0853626112453,6.77228121849221,9.61311509176035,14.591621395761,3.84548835759178,14.2817296476825,5.94818571662942],"target":10.0},"CORUNDUM":{"past_rates":[46.5637457316207,49.0066784393883,48.5971158200532,48.0958385381812,48.3584634941204,45.5388537922164,43.3306752969333,44.0387921058397,44.3324886523958,47.7171695055122],"target":47.0064399433141},"KYANITE":{"past_rates":[59.8791458420046,64.2459075281605,66.7695718467051,59.7965351989026,59.8838057917377,54.9514977873152,56.4421001011451,60.4661167126869,57.3117738517954,63.4304981607489],"target":63.7691287997866},"OLIVINE":{"past_rates":[7.4655856069382,1.0,1.0,1.0,24.14071819157,32.4164779627546,60.0346421419083,3.01164759956833,1.0,13.6928542333802],"target":8.24970709721707},"QUARTZ":{"past_rates":[110.462411936918,99.0985671097251],"target":99.5812900184579},"TOPAZ":{"past_rates":[38.3755339639794,22.1955231799478,17.7429238729256,16.2221743656724,37.2720621811583,28.5627426322381,31.8202718074999,20.1555855559104,21.0863766540674,19.6619826840036],"target":18.740424535789}},"skill_nodes":{"root":0,"trees":[]},"states":{"BLEEG":{"discovered":true,"read_dialogue":true,"revealed":true},"CLICKY":{"discovered":false,"read_dialogue":false,"revealed":false},"EXCHANGE":{"discovered":true,"read_dialogue":true,"revealed":true},"FACTORY":{"discovered":true,"read_dialogue":true,"revealed":true},"GARAGE":{"discovered":true,"read_dialogue":true,"revealed":true},"LAUNCH":{"discovered":true,"read_dialogue":true,"revealed":true},"MERCHANT":{"discovered":true,"read_dialogue":true,"revealed":true},"SCIENTIST":{"discovered":true,"read_dialogue":true,"revealed":true},"SETTINGS":{"discovered":true,"read_dialogue":true,"revealed":true},"SHIKOBA":{"discovered":false,"read_dialogue":false,"revealed":false}},"stats":{"armour":6,"bar_replenish":3,"blue_damage":5,"blue_portion":6,"blue_yield":4,"boost_discount":8,"boost_distance":4,"click_speed":1,"damage_boost":1,"fuel_boost":1,"fuel_capacity":20,"green_damage":4,"green_portion":2,"green_yield":6,"hit_size":13,"hit_strength":13,"kruos_fuel_capacity":1,"kruos_thruster_speed":1,"lightning_chance":7,"lightning_damage":5,"lightning_length":2,"mineral_value":6,"more_minerals":1,"orange_damage":6,"orange_portion":2,"orange_yield":10,"powerup_duration":1,"powerup_spawn_rate":1,"powerup_ultra_chance":1,"red_damage":1,"red_portion":114,"red_yield":1,"rock_boost":3,"speed_boost":1,"thruster_speed":20,"unlocked_powerups":1},"version":"1.1"}
	#""")
	
	if !data.get("version") or data.version != CURRENT_VERSION:
		return
	
	GameManager.day = data.day
	
	for m in data.minerals:
		GameManager.player.minerals[Enums.Mineral[m]] = data.minerals[m]
	
	for s in data.settings:
		Settings.set_setting(Settings.SettingType[s], data.settings[s])
	
	for m in data.rates:
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates.clear()
		GameManager.exchange_rates[Enums.Mineral[m]].target.target = data.rates[m].target
		GameManager.exchange_rates[Enums.Mineral[m]].past_rates = data.rates[m].past_rates
		GameManager.exchange_rates[Enums.Mineral[m]].refresh()
	
	StatManager._set_base_stats()
	StatManager.portions_changed = true
	for stat in data.stats.keys():
		# print_debug(stat, ", saved levels: ", data.stats[stat] - 1)
		for i in range(data.stats[stat] - StatManager.get_stat(stat).level):
			StatManager.upgrade_stat(stat)
	
	GameManager.player.owned_items.clear()
	for item in data.items.keys():
		GameManager.player.all_items[item].level = 1
		GameManager.player.owned_items[item] = GameManager.player.all_items[item]
		for i in range(data.items[item] - 1):
			GameManager.player.owned_items[item].upgrade()
	
	GameManager.player.reset_discovered()
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
