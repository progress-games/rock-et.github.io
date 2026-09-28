extends Node

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum Reward {
	NOTHING,
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

const RARITY_COLOURS = {
	Rarity.COMMON: Color(0.78, 0.863, 0.816, 1.0),
	Rarity.UNCOMMON: Color(0.118, 0.737, 0.451, 1.0),
	Rarity.RARE: Color(0.302, 0.396, 0.706, 1.0),
	Rarity.EPIC: Color(0.565, 0.369, 0.663, 1.0),
	Rarity.LEGENDARY: Color(0.969, 0.588, 0.09, 1.0)
}

@export var default_stats: Dictionary[DroneEnums.DroneType, DroneStats]

@export_group("floatie")
@export var drone_rarities: Dictionary[Rarity, DroneRarity]
@export var drone_colours: Dictionary[DroneEnums.DroneType, ColorPair]

@export_group("positions")
@export var drone_effects: Dictionary[DroneEnums.DroneEffect, DroneEffect]

var owned_drones: Array[DroneStats]
var equipped_drones: Array[DronePosition]
var upgrade_funcs: Dictionary[DroneEnums.DroneType, Dictionary]

var drone_shape: DroneShape

signal drone_added()
signal drone_removed

"""
DronePosition -> DroneTile
DroneTile should hold DroneStats
"""
func _ready() -> void:
	init_upgrade_funcs()
	#add_new_drone(DroneEnums.DroneType.FLAILER)
	#add_new_drone(DroneEnums.DroneType.LASER)
	#add_new_drone(DroneEnums.DroneType.SNIPER)
	#add_new_drone(DroneEnums.DroneType.PRICKER)
	#add_new_drone(DroneEnums.DroneType.LAUNCHER)
	#add_new_drone(DroneEnums.DroneType.FLAMETHROWER)
	#add_new_drone(DroneEnums.DroneType.SPRAYER)
	#add_new_drone(DroneEnums.DroneType.SHOTGUNNER)
	#add_new_drone(DroneEnums.DroneType.GUNNER)
	#add_new_drone(DroneEnums.DroneType.GUNNER)
	#add_new_drone(DroneEnums.DroneType.GUNNER)
	add_new_drone(DroneEnums.DroneType.GUNNER)
	
	
	GameManager.state_changed.connect(
		func (s: Enums.State):
			if s == Enums.State.MISSION && !GameManager.player.has_discovered_state(Enums.State.FLOATIE):
				mission_started()
			if s != Enums.State.MISSION and equipped_drones.size() > 0:
				mission_ended()
	)
	
	drone_shape = DroneShape.new()

func get_quantity(drone_stats: DroneStats) -> int:
	var drone_type = drone_stats.drone_type
	var level = drone_stats.level
	return owned_drones.reduce(
		func (a, x):
			return a + (1 if x.drone_type == drone_type && x.level == level else 0),
			0
	)

func init_upgrade_funcs() -> void:
	upgrade_funcs = {
		DroneEnums.DroneType.GUNNER: {
			DroneEnums.StatType.FIRE_RATE: func (v): return v + 0.2,
			DroneEnums.StatType.AMMO: func (v): return v + 5,
			DroneEnums.StatType.DAMAGE: func (v): return v + 0.2,
			DroneEnums.StatType.RANGE: func (v): return v + 20
		},
		DroneEnums.DroneType.SHOTGUNNER: {
			DroneEnums.StatType.FIRE_RATE: func (v): return v + 0.1,
			DroneEnums.StatType.AMMO: func (v): return v + 6,
			DroneEnums.StatType.DAMAGE: func (v): return v + 0.2,
			DroneEnums.StatType.PIERCE: func (v): return v + 1,
			DroneEnums.StatType.AMMO_PER_CRATE: func (v): return v + 4
		},
		DroneEnums.DroneType.SPRAYER: {
			DroneEnums.StatType.FIRE_RATE: func (v): return v + 1,
			DroneEnums.StatType.DAMAGE: func (v): return v + 0.05,
			DroneEnums.StatType.AMMO: func (v): return v + 15,
			DroneEnums.StatType.AMMO_PER_CRATE: func (v): return v + 10
		}
	}

func add_new_drone(drone_type: DroneEnums.DroneType) -> void:
	owned_drones.append(get_new_drone(drone_type))
	drone_added.emit()

func add_drone(drone: DroneStats) -> void:
	owned_drones.append(drone)
	drone_added.emit()

func mission_started() -> void:
	var drone_pos = DronePosition.new()
	drone_pos.drone_stats = owned_drones[0]
	equipped_drones.append(drone_pos)

func mission_ended() -> void:
	equipped_drones.clear()

# Array[DroneStats]
func get_unique_drones() -> Array:
	return owned_drones.reduce(
		func (a, x: DroneStats):
			return a if a.any(func (_x): return x.level == _x.level && x.drone_type == _x.drone_type) \
				else a + [x], [])

func get_drone_upgrade_stat(drone: DroneStats) -> DroneEnums.StatType:
	var drone_upgrade_funcs = upgrade_funcs.get(drone.drone_type)
	var upgrading_idx: int = drone.level % drone_upgrade_funcs.size()
	var upgrading_stat: DroneEnums.StatType = drone_upgrade_funcs.keys()[upgrading_idx]
	
	return upgrading_stat

func upgrade_drone(drone: DroneStats) -> void:
	var upgrading_stat = get_drone_upgrade_stat(drone)
	var current_value: float = drone.stats.get(upgrading_stat)
	
	drone.stats.set(
		upgrading_stat, 
		upgrade_funcs[drone.drone_type][upgrading_stat].call(current_value)
	)
	drone.level += 1

func get_new_drone(drone_type: DroneEnums.DroneType) -> DroneStats:
	return default_stats.get(drone_type).duplicate_deep()

func remove_drone(drone: DroneStats) -> void:
	var id = drone.get_instance_id()
	var idx = owned_drones.find_custom(func (x): return x.get_instance_id() == id)
	owned_drones.pop_at(idx)
	drone_removed.emit()

func get_drone_sprite(drone_type: DroneEnums.DroneType) -> CompressedTexture2D:
	return load("res://mission/drones/assets/body/" + \
		DroneEnums.DroneType.find_key(drone_type) + ".png")

func get_bullet_sprite(drone_type: DroneEnums.DroneType) -> CompressedTexture2D:
	return load("res://mission/drones/assets/bullet/" + \
		DroneEnums.DroneType.find_key(drone_type) + ".png")

func get_reward(reward: Reward) -> DroneEnums.DroneType:
	var rarity = reward - 1
	return drone_rarities[rarity].drones.pick_random()

func get_upgrade_duration(drone: DroneStats, levels: int) -> int:
	var rarity = 0
	while !drone_rarities[rarity].drones.has(drone.drone_type):
		rarity += 1
	
	return int(ceil((rarity + 1) * (levels / 2.)))

func get_rarity_colour(drone_type: DroneEnums.DroneType) -> Color:
	var drone_rarity: Rarity
	for rarity in drone_rarities.keys():
		if drone_type in drone_rarities[rarity].drones:
			drone_rarity = rarity
			break
	
	return RARITY_COLOURS[drone_rarity]
