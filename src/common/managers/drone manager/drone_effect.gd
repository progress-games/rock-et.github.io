extends Resource
class_name DroneEffect

@export var texture: CompressedTexture2D
@export var name: String
@export var description: String
@export var display_type: Stat.DisplayType = Stat.DisplayType.BASIC
@export var effect: DroneEnums.DroneEffect

var level: int = 0

func get_stat() -> Stat:
	return StatManager.get_stat("dp_" + DroneEnums.DroneEffect.find_key(effect).to_lower())

# next level shows the upgraded value in green
func get_description(next_level: bool = false) -> String:
	var v = get_stat().value if !next_level else get_stat().next_level.value
	
	if display_type == Stat.DisplayType.CHANCE:
		v *= 100
	
	var val = str(snappedf(v, 0.01)).rstrip("0").rstrip(".")
	
	var d = description.replace("[VALUE]", 
		("[color=#1ebc73ff]" + str(val) + "[/color]") if next_level else str(val))
	
	if effect == DroneEnums.DroneEffect.HITBAR_MULT:
		return d + " (" + \
			str(get_stat().value * StatManager.get_portion_power("orange", "damage")) + ")"
	
	return d

func load_drone(drone: Drone) -> void:
	match effect:
		DroneEnums.DroneEffect.DAMAGE:
			drone.damage *= get_stat().value
		DroneEnums.DroneEffect.FIRE_RATE:
			drone.fire_rate += get_stat().value
		DroneEnums.DroneEffect.PIERCE:
			drone.pierce += int(ceil(get_stat().value))
		DroneEnums.DroneEffect.HOMING_STRENGTH:
			drone.homing_strength += get_stat().value
		DroneEnums.DroneEffect.BAUXITE_CHANCE:
			drone.bauxite_chance += get_stat().value
		DroneEnums.DroneEffect.CRIT_CHANCE:
			drone.crit_chance += get_stat().value
		DroneEnums.DroneEffect.DOUBLE_SHOT_CHANCE:
			drone.double_shot_chance += get_stat().value
		DroneEnums.DroneEffect.EXTRA_LEVELS:
			var new_stats = DroneManager.get_new_drone(drone.drone_type)
			for i in range(drone.drone_stats.level - 1 + int(ceil(get_stat().value))):
				DroneManager.upgrade_drone(new_stats)
			drone.set_stats(new_stats)
		DroneEnums.DroneEffect.LIGHTNING_CHANCE:
			drone.lightning_chance += get_stat().value
		DroneEnums.DroneEffect.FREEZE_CHANCE:
			drone.freeze_chance += get_stat().value
		DroneEnums.DroneEffect.AMMO_CAPACITY:
			drone.ammo_capacity += int(ceil(get_stat().value))
			drone.current_ammo = drone.ammo_capacity
		DroneEnums.DroneEffect.GHOST_AMMO:
			drone.ghost_ammo_chance += get_stat().value
		DroneEnums.DroneEffect.BULLET_BOUNCES:
			drone.bullet_bounces += int(ceil(get_stat().value))
		DroneEnums.DroneEffect.HITBAR_MULT:
			drone.damage += get_stat().value * StatManager.get_portion_power("orange", "damage")
