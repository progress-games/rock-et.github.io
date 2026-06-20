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
	var settings = Settings.values
	
	var save = {
		"day": GameManager.day,
		"planet": GameManager.planet,
		"minerals": {},
		"stats": {},
		"items": {},
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
		#{"day":40,"discovered_minerals":["AMETHYST","TOPAZ","KYANITE","OLIVINE","CORUNDUM","GOLD"],"items":{"binoculars":1,"boxing_gloves":5,"stopwatch":1},"minerals":{"AMETHYST":1440.0,"CORUNDUM":28.0,"GOLD":1221.55783827758,"KYANITE":278.0,"OLIVINE":708.0,"QUARTZ":0.0,"TOPAZ":878.0,"TUGTUPITE":0.0},"planet":1,"rates":{"AMETHYST":{"past_rates":[16.8420115253531,4.91111033694996,18.0868918108244,3.78602215130368,13.1413790713252,17.4085775600676,5.17239395574522,28.181991714859,20.656536922919,16.3723085279368],"target":20.0080898941064},"CORUNDUM":{"past_rates":[42.6345772250552,53.1449935012996,42.0377612213557,55.4884105681678,41.6887882625337,46.3427191555406,38.4977561888796,48.2743506021409,48.0090477937184,41.9124945989449],"target":41.0217519198405},"KYANITE":{"past_rates":[84.5608293052079,83.3880471374475,80.3639394000235,83.6481876422974,84.1212815504983,79.0074355646548,76.6216000979232,77.4225224105838,90.0335395999005,80.4059102350218],"target":85.4845940933979},"OLIVINE":{"past_rates":[9.18208026954123,1.0,1.0,1.0,1.0,14.3618857152342,64.7087316236702,30.6574810632795,1.0,1],"target":-26.4836555776205},"QUARTZ":{"past_rates":[133.896486371068,135.034038489663,104.335221525734,111.514086412426,130.718588486074,86.4063710027434,103.984141684001,104.840017838837,110.662088207052,90.6502875925918],"target":91.5223449090763},"TOPAZ":{"past_rates":[20.9850845708434,25.4090997502839,25.949646997752,32.2548313468676,36.4674344173963,23.550004854146,34.0987050857692,22.7746701166663,24.4448372644372,40.6437462928227],"target":22.7124320755177}},"settings":{"AMBIENCE_VOLUME":50,"MUSIC_VOLUME":50,"SFX_VOLUME":50},"skill_nodes":{"root":0,"trees":[]},"states":{"BLEEG":{"discovered":true,"read_dialogue":true,"revealed":true},"CLICKY":{"discovered":false,"read_dialogue":false,"revealed":false},"EXCHANGE":{"discovered":true,"read_dialogue":true,"revealed":true},"FACTORY":{"discovered":true,"read_dialogue":false,"revealed":true},"GARAGE":{"discovered":true,"read_dialogue":false,"revealed":true},"LAUNCH":{"discovered":true,"read_dialogue":false,"revealed":true},"MERCHANT":{"discovered":true,"read_dialogue":true,"revealed":true},"SCIENTIST":{"discovered":true,"read_dialogue":true,"revealed":true},"SETTINGS":{"discovered":true,"read_dialogue":false,"revealed":true},"SHIKOBA":{"discovered":false,"read_dialogue":false,"revealed":false}},"stats":{"armour":1,"autoclick_powerup":1,"bar_replenish":3,"blue_damage":7,"blue_portion":6,"blue_yield":4,"boost_discount":1,"boost_distance":1,"click_speed":8,"double_click_powerup":1,"double_minerals_powerup":1,"explosion_powerup":1,"fuel_boost":1,"fuel_capacity":16,"green_damage":2,"green_portion":2,"green_yield":4,"hit_size":11,"hit_strength":9,"insta_break_powerup":1,"kruos_hit_size":1,"kruos_hit_strength":1,"kruos_thruster_speed":1,"lightning_chance":7,"lightning_damage":5,"lightning_length":3,"mineral_value":7,"more_rocks_powerup":1,"orange_damage":3,"orange_portion":2,"orange_yield":8,"pause_powerup":1,"powerup_capacity":1,"powerup_spawn_rate":1,"powerup_ultra_chance":1,"red_damage":2,"red_portion":2,"red_yield":2,"rock_boost":1,"size_up_powerup":1,"speed_boost_powerup":1,"thruster_speed":20,"unlocked_powerups":1},"version":"1.1"}
	#""")
	
	if !data.get("version") or data.version != CURRENT_VERSION:
		return
	
	GameManager.day = data.day
	
	for m in data.minerals:
		GameManager.player.minerals[Enums.Mineral[m]] = data.minerals[m]
	
	for s in data.settings:
		Settings.set_setting(Settings.SettingType[s], data.settings[s])
	
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
