extends Node

enum BounceEffect {
	UNLOCK,
	
	LIGHTNING,
	FREEZE,
	WEAK,
	
	EXPLOSION,
	MINERALS,
	IMMUNE,
	
	FRAGS,
	BURN,
}

enum StatType {
	UNLOCK,
	CHANCE,
	DAMAGE,
	LIGHTNING_LENGTH,
	DURATION,
	WEAK_AMOUNT,
	SLOW,
	ARMOUR,
	MINERAL_AMOUNT,
	FRAG_AMOUNT,
	EXPLOSION_SIZE,
	EXPLOSION_DAMAGE,
	HOMING,
	PIERCE
}

const COLLIDED := "[img tooltip='asteroids that hit your ship']res://common/managers/bounce effect manager/assets/collided.png[/img]"

const COLOURS := {
	BounceEffect.UNLOCK: Color(0.18, 0.133, 0.184, 1.0),
	BounceEffect.LIGHTNING: Color(0.302, 0.608, 0.902, 1.0),
	BounceEffect.FREEZE: Color(0.561, 0.827, 1.0, 1.0),
	BounceEffect.WEAK: Color(0.984, 0.725, 0.329, 1.0),
	
	BounceEffect.EXPLOSION: Color(0.969, 0.588, 0.09, 1.0),
	BounceEffect.MINERALS: Color(0.565, 0.369, 0.663, 1.0),
	BounceEffect.IMMUNE: Color(0.698, 0.729, 0.565, 1.0),
	
	BounceEffect.FRAGS: Color(0.918, 0.31, 0.212, 1.0),
	BounceEffect.BURN: Color(0.682, 0.137, 0.204, 1.0)
}

const STAT_DESCRIPTIONS := {
	BounceEffect.UNLOCK: {
		StatType.UNLOCK: "unlock [collided] effects"
	},
	BounceEffect.LIGHTNING: {
		StatType.UNLOCK: "[collided] have a chance to spark lightning",
		StatType.CHANCE: "+[VALUE]% lightning chance",
		StatType.DAMAGE: "+[VALUE] lightning damage",
		StatType.LIGHTNING_LENGTH: "+[VALUE] lightning length"
	},
	BounceEffect.FREEZE: {
		StatType.UNLOCK: "asteroids hit with lightning have a chance to freeze",
		StatType.CHANCE: "+[VALUE]% freeze chance",
		StatType.DURATION: "+[VALUE]s freeze duration"
	},
	BounceEffect.WEAK: {
		StatType.UNLOCK: "asteroids hit with lightning are weakened",
		StatType.WEAK_AMOUNT: "weakened asteroids take +[VALUE]% more damage",
		StatType.SLOW: "weakened asteroids move +[VALUE]% slower"
	},
	BounceEffect.EXPLOSION: {
		StatType.UNLOCK: "[collided] have a chance to explode",
		StatType.CHANCE: "+[VALUE]% chance to explode",
		StatType.EXPLOSION_SIZE: "+[VALUE]px explosion size",
		StatType.EXPLOSION_DAMAGE: "+[VALUE] explosion damage"
	},
	BounceEffect.IMMUNE: {
		StatType.UNLOCK: "[collided] have a chance be reflected",
		StatType.CHANCE: "+[VALUE]% chance to reflect asteroids",
		StatType.DAMAGE: "+[VALUE] damage to reflected asteroids"
	},
	BounceEffect.MINERALS: {
		StatType.UNLOCK: "[collided] have a chance to drop minerals",
		StatType.CHANCE: "+[VALUE]% mineral drop chance",
		StatType.MINERAL_AMOUNT: "+[VALUE]% minerals dropped"
	},
	BounceEffect.FRAGS: {
		StatType.UNLOCK: "[collided] have a chance to shoot asteroid fragments",
		StatType.FRAG_AMOUNT: "+[VALUE] asteroid fragments",
		StatType.CHANCE: "+[VALUE]% fragment chance"
	},
	BounceEffect.BURN: {
		StatType.UNLOCK: "asteroids hit by a frag have a chance to burn",
		StatType.CHANCE: "+[VALUE]% burn chance",
		StatType.DAMAGE: "+[VALUE] burn damage"
	}
}

const DEFAULT_STATS = {
	BounceEffect.LIGHTNING: {
		StatType.CHANCE: 0.1,
		StatType.DAMAGE: 2,
		StatType.LIGHTNING_LENGTH: 1
	}
}

var stats: Dictionary[BounceEffect, Dictionary]

var unlocked_effects: Array[BounceEffect] = []

func _ready() -> void:
	for k in DEFAULT_STATS.keys():
		stats.set(k, {})
		for s in DEFAULT_STATS[k].keys():
			stats[k].set(s, DEFAULT_STATS[k][s])

func get_description(effect_type: BounceEffect, stat_type: StatType, amount: float) -> String:
	var v: String
	if stat_type == StatType.CHANCE:
		v = str(int(ceil(amount * 100)))
	else:
		v = str(int(ceil(amount)))
	
	return STAT_DESCRIPTIONS[effect_type][stat_type].replace("[VALUE]", v).replace("[collided]", COLLIDED)

func is_unlocked(effect_type: BounceEffect) -> bool:
	return unlocked_effects.has(effect_type)

func upgrade_stat(effect_type: BounceEffect, stat_type: StatType, amount: float) -> void:
	if stat_type == StatType.UNLOCK:
		unlocked_effects.append(effect_type)
		return
	
	stats[effect_type][stat_type] += amount

func get_unlock_sprite(effect_type: BounceEffect) -> Texture2D:
	var path = "res://common/managers/bounce effect manager/assets/unlock/"
	path += BounceEffect.find_key(effect_type).to_lower()
	path += ".png"
	return load(path)

func get_stat_sprite(stat_type: StatType) -> Texture2D:
	var path = "res://common/managers/bounce effect manager/assets/stats/"
	path += StatType.find_key(stat_type).to_lower()
	path += ".png"
	return load(path)

func get_colour(effect_type: BounceEffect) -> Color:
	return COLOURS.get(effect_type)
