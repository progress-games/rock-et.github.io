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

@export var default_stats: Dictionary[DroneEnums.DroneType, DroneStats]

@export_group("floatie")
@export var reward_chances: Dictionary[Reward, float]
@export var drone_rarities: Dictionary[Rarity, DroneRarity]
@export var drone_colours: Dictionary[DroneEnums.DroneType, ColorPair]

@export_group("positions")
@export var drone_effects: Dictionary[DroneEnums.DroneEffect, DroneEffect]

var owned_drones: Array[DroneStats]
var equipped_drones: Array[DronePosition]
var upgrade_funcs: Dictionary[DroneEnums.DroneType, Dictionary]

signal drone_added()

func _ready() -> void:
	init_upgrade_funcs()
	add_new_drone(DroneEnums.DroneType.FLAILER)
	add_new_drone(DroneEnums.DroneType.LASER)
	add_new_drone(DroneEnums.DroneType.SNIPER)
	add_new_drone(DroneEnums.DroneType.PRICKER)
	add_new_drone(DroneEnums.DroneType.LAUNCHER)
	add_new_drone(DroneEnums.DroneType.FLAMETHROWER)
	add_new_drone(DroneEnums.DroneType.SPRAYER)
	add_new_drone(DroneEnums.DroneType.SHOTGUNNER)
	add_new_drone(DroneEnums.DroneType.GUNNER)
	
	GameManager.state_changed.connect(
		func (s: Enums.State):
			if s == Enums.State.MISSION:
				mission_started()
			elif equipped_drones.size() > 0:
				mission_ended()
	)

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
			DroneEnums.StatType.FIRE_RATE: func (v): return v + 0.05
		},
		DroneEnums.DroneType.SHOTGUNNER: {
			DroneEnums.StatType.FIRE_RATE: func (v): return v + 0.05
		}
	}

func add_new_drone(drone_type: DroneEnums.DroneType) -> void:
	owned_drones.append(get_new_drone(drone_type))
	drone_added.emit()

func add_drone(drone: DroneStats) -> void:
	owned_drones.append(drone)

func mission_started() -> void:
	if GameManager.planet != Enums.Planet.VULCAN: return
	
	var new_position = DronePosition.new()
	new_position.drone_stats = owned_drones[0]
	equipped_drones.append(new_position)
	
	var new_position2 = DronePosition.new()
	new_position2.x = 1
	new_position2.drone_stats = owned_drones[1]
	equipped_drones.append(new_position2)
	
	var new_position3 = DronePosition.new()
	new_position3.y = 1
	new_position3.drone_stats = owned_drones[2]
	equipped_drones.append(new_position3)
	
	var new_position4 = DronePosition.new()
	new_position4.x = 1
	new_position4.y = 1
	new_position4.drone_stats = owned_drones[3]
	equipped_drones.append(new_position4)

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
	owned_drones.erase(drone)

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
