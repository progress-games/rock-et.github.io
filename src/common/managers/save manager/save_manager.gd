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

signal get_unlocked_nodes(dict: Dictionary)
signal set_unlocked_nodes(dict: Dictionary)

signal read_dialogue(state: Enums.State)

signal loaded_save()

var save: SaveData

func _ready() -> void:
	for file_name in DirAccess.get_files_at("user://"):
		if file_name.ends_with(".save"):
			DirAccess.remove_absolute("user://" + file_name)
	
	GameManager.day_changed.connect(redirect(day_changed))
	GameManager.planet_changed.connect(redirect(planet_changed))
	GameManager.add_mineral.connect(redirect(update_mineral_amount))
	GameManager.state_changed.connect(redirect(update_discovered_states))
	GameManager.state_revealed.connect(redirect(state_revealed))
	GameManager.tutorial_read.connect(redirect(tutorial_read))
	GameManager.endless_started.connect(redirect(endless_started))
	
	
	GameManager.player.mineral_discovered.connect(redirect(update_discovered_minerals))
	GameManager.player.item_upgraded.connect(redirect(item_upgraded))
	GameManager.player.potion_bought.connect(redirect(potion_bought))
	GameManager.player.potion_used.connect(redirect(potion_used))
	
	read_dialogue.connect(redirect(update_dialogue_progress))
	
	StatManager.stat_upgraded.connect(redirect(stat_upgraded))
	
	# wheel upgrade chosen
	# drink bought

func endless_started() -> void:
	save.endless_mode = true
	store_save()

func tutorial_read(t: Enums.Tutorial) -> void:
	save.tutorial_progress.append(t)
	store_save()

func is_loading() -> bool:
	return loading_save

func redirect(f: Callable) -> Callable:
	return func (a=null,b=null): 
		if !SaveManager.is_loading(): 
			match f.get_argument_count():
				0: f.call()
				1: f.call(a)
				2: f.call(a, b)

func day_changed(day: int) -> void:
	save.day = day
	store_save()

func planet_changed(planet: Enums.Planet) -> void:
	save.planet = planet
	store_save()

func update_discovered_states(state: Enums.State) -> void:
	save.states[state].discovered = true
	store_save()

func state_revealed(state: Enums.State) -> void:
	save.states[state].revealed = true
	store_save()

func stat_upgraded(stat: Stat) -> void:
	save.stat_levels[stat.stat_name] += 1
	store_save()

func update_mineral_amount(mineral: Enums.Mineral, _a) -> void:
	save.mineral_amounts.set(mineral, GameManager.player.get_mineral(mineral))

func update_discovered_minerals(mineral: Enums.Mineral) -> void:
	save.discovered_minerals.append(mineral)
	store_save()

func update_dialogue_progress(state: Enums.State) -> void:
	save.states[state].dialogue_progress += 1
	store_save()

func item_upgraded(item_name: String) -> void:
	if !save.owned_items.has(item_name):
		save.owned_items.set(item_name, 1)
	save.owned_items[item_name] = GameManager.player.all_items[item_name].level
	store_save()

func potion_bought(potion_name: String) -> void:
	save.owned_potions.append(potion_name)
	store_save()

func potion_used(potion_name: String) -> void:
	save.owned_potions.erase(potion_name)
	store_save()

func new_save(save_name: String = "save") -> void:
	save = SaveData.new()
	
	save.rng_seed = randi_range(0, 9999999)
	seed(save.rng_seed)
	
	save.day = GameManager.day
	
	save.stat_levels = {}
	for stat_name in StatManager.stats.keys():
		save.stat_levels.set(stat_name, StatManager.stats[stat_name].level)
	
	save.states = {}
	for state in Enums.State.values():
		save.states.set(state, StateData.new())
	
	save.mineral_amounts = {}
	for mineral in Enums.Mineral.values():
		save.mineral_amounts.set(mineral, 0.)
	
	store_save(save_name)
	
	loaded_save.emit()
	loading_save = false

func store_save(save_name: String = "save") -> void:
	ResourceSaver.save(save, "user://" + save_name + ".tres")

func load_save(save_name: String = "save") -> void:
	save = load("user://" + save_name + ".tres")
	loading_save = true
	
	seed(save.rng_seed)
	
	if save.endless_mode: GameManager.start_endless()
	
	GameManager.day_changed.emit(save.day)
	GameManager.planet_changed.emit(save.planet)
	save.tutorial_progress.map(GameManager.read_tutorial)
	
	StatManager._set_base_stats()
	for stat_name in save.stat_levels.keys():
		var level = save.stat_levels[stat_name]
		for i in range(level - 1):
			StatManager.upgrade_stat(stat_name) 
	
	GameManager.player.owned_items.clear()
	for item_name in save.owned_items.keys():
		for i in range(save.owned_items[item_name]):
			GameManager.player.upgrade_item(item_name)
	
	GameManager.player.owned_potions = save.owned_potions
	
	for mineral in save.mineral_amounts:
		GameManager.player.minerals[mineral] = save.mineral_amounts[mineral]
	
	GameManager.player.reset_discovered()
	for mineral in save.discovered_minerals:
		GameManager.player.discover_mineral(mineral)
	
	for state in save.states.keys():
		if save.states[state].discovered:
			GameManager.player.discover_state(state)
	
	# revealed states are managed in home
	# dialogue progress is managed in dialogue managers
	
	loaded_save.emit()
	loading_save = false

func save_exists(save_name: String = "save") -> bool:
	if FileAccess.file_exists("user://" + save_name + ".tres"):
		var s = get_save()
		return s.day > 1
	
	return false

func load_if_exists(save_name: String = "save") -> void:
	if save_exists(save_name): 
		load_save(save_name)

func get_save(save_name: String = "save") -> SaveData:
	return load("user://" + save_name + ".tres")

func get_state_data(state: Enums.State) -> StateData:
	return save.states.get(state)
