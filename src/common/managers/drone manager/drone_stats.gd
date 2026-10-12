extends Resource
class_name DroneStats

"""
This simply holds data for a drone of some type at some level
this drone will never level up or change type
"""

const DESCRIPTIONS := {
	DroneEnums.DroneType.GUNNER: "all rounder",
	DroneEnums.DroneType.SHOTGUNNER: "shoots 6 bullets at a time",
	DroneEnums.DroneType.SPRAYER: "sprays low-damage bullets",
	DroneEnums.DroneType.SNIPER: "targets the toughest asteroid",
	DroneEnums.DroneType.LAUNCHER: "launches grenades",
	DroneEnums.DroneType.HEATSEEKER: "shoots homing bullets",
	DroneEnums.DroneType.PRICKER: "sprays bullets in a ring",
	DroneEnums.DroneType.FLAILER: "spins a deadly flail",
	DroneEnums.DroneType.LASER: "shoots a deadly laser",
	DroneEnums.DroneType.FLAMETHROWER: "blasts flames"
}

const BASE_COLOUR := Color(0.086, 0.353, 0.298, 1.0)
const UPGRADE_COLOUR := Color(0.137, 0.565, 0.388, 1.0)

@export var drone_type: DroneEnums.DroneType
@export var stats: Dictionary[DroneEnums.StatType, float]

var level: int = 1

func get_tooltip() -> String:
	return DroneEnums.DroneType.find_key(drone_type).to_lower() + "\n" + DESCRIPTIONS[drone_type]

func get_stat(stat: DroneEnums.StatType) -> float:
	return stats.get(stat, 0.)

func n(a: float) -> String:
	return str(snappedf(a, 0.01)).rstrip("0").rstrip(".")

func colour_text(txt: String, colour: Color) -> String:
	return "[color=#" + colour.to_html(false) + "]" + txt + "[/color]"

func get_upgrade_details(levels: int) -> String:
	var upgraded_stats = []
	
	var temp = DroneManager.get_new_drone(drone_type)
	for l in range(level - 1): DroneManager.upgrade_drone(temp)
	
	for l in levels:
		var s = DroneManager.get_drone_upgrade_stat(temp)
		if s not in upgraded_stats: upgraded_stats.append(s)
		DroneManager.upgrade_drone(temp)
	
	var output = "[table=4]"
	
	for stat in upgraded_stats:
		output += "[cell]"
		output += colour_text(DroneEnums.StatType.find_key(stat).to_lower().replace("_", " ") + ":",  BASE_COLOUR)
		output += "[/cell][cell]" + colour_text(n(get_stat(stat)), BASE_COLOUR) + "[/cell]"
		output += "[cell][img color=" + UPGRADE_COLOUR.to_html(false) + "]"
		output += "res://common/ui/upgrades/upgrade_arrow.png[/img][/cell]"
		output += "[cell]" + colour_text(n(temp.get_stat(stat)), UPGRADE_COLOUR) + "[/cell][/color]"
	
	return output + "[/table]"
