extends Node
class_name DroneEnums

enum DroneType {
	GUNNER,
	SHOTGUNNER,
	SPRAYER,
	FLAMETHROWER,
	SNIPER,
	LAUNCHER,
	PRICKER,
	LASER,
	HEATSEEKER,
	FLAILER
}

# SHOCKER
# SLASHER
# DISINTEGRATER
# AIR_STRIKER
# FINANCIER

enum StatType {
	FIRE_RATE,
	AMMO,
	DAMAGE,
	SPREAD,
	PIERCE,
	RANGE,
	BULLET_SPEED,
	SPEED_VARIANCE,
	AMMO_PER_CRATE,
	BURN_DAMAGE,
	BURN_DURATION,
	EXPLOSION_DAMAGE,
	EXPLOSION_SIZE,
	BULLETS_PER_SHOT,
	LASER_DPS,
}

"""
shuffle positions
centre: 
	nothing
level 1 out: 
	fire rate
	dmg
	pierce
	range
level 2 out: 
	homing strength
	bauxite chance 
	shard chance on break
	crit chance
	double shot chance
	+ level
	bullet bounces
	life steal
	lightning chance
	freeze chance
	lightning chance
	ammo yield
"""

enum DroneEffect {
	NOTHING,
	FIRE_RATE,
	DMG,
	PIERCE,
	RANGE,
	HOMING_STRENGTH,
	BAUXITE_CHANCE,
	TEPHRA_CHANCE,
	CRIT_CHANCE,
	DOUBLE_SHOT_CHANCE,
	EXTRA_LEVELS,
	BULLET_BOUNCES,
	LIFE_STEAL,
	LIGHTNING_CHANCE,
	FREEZE_CHANCE,
	AMMO_YIELD,
	EMPTY_TILE,
	HITBAR_MULT # bullets do +10% of orange hitbar damage (+3 dmg)
}
