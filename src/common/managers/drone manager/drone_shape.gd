extends Object
class_name DroneShape

const SHAPES: Array[Array] = [
	[
		[0, 3, 3, 3, 0],
		[3, 2, 0, 2, 3],
		[3, 0, 1, 0, 3],
		[3, 2, 0, 2, 3],
		[0, 3, 3, 3, 0]
	]
]

# array of x and y positions that need to be unlocked to unlock this tile
const SHAPE_DEPENDENCIES: Array[Array] = [
	[
		[[], [[1, 1]], [[1, 0], [3, 0]], [[3, 1]], []],
		[[[1, 1]], [[2, 2]], [], [[2, 2]], [[3, 1]]],
		[[[0, 1], [0, 3]], [], [[0, 0]], [], [[4, 1], [4, 3]]],
		[[[1, 3]], [[2, 2]], [], [[2, 2]], [[3, 3]]],
		[[], [[1, 3]], [[1, 4], [3, 4]], [[3, 3]], []]
	]
]

const LEVEL_EFFECTS: Dictionary[int, Array] = {
	0: [
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE,
		DroneEnums.DroneEffect.EMPTY_TILE
	],
	1: [
		DroneEnums.DroneEffect.NOTHING
	],
	2: [
		DroneEnums.DroneEffect.FIRE_RATE, 
		DroneEnums.DroneEffect.DMG, 
		DroneEnums.DroneEffect.PIERCE, 
		DroneEnums.DroneEffect.RANGE
	],
	3: [
		DroneEnums.DroneEffect.HOMING_STRENGTH,
		DroneEnums.DroneEffect.BAUXITE_CHANCE,
		DroneEnums.DroneEffect.TEPHRA_CHANCE,
		DroneEnums.DroneEffect.CRIT_CHANCE,
		DroneEnums.DroneEffect.DOUBLE_SHOT_CHANCE,
		DroneEnums.DroneEffect.EXTRA_LEVELS,
		DroneEnums.DroneEffect.BULLET_BOUNCES,
		DroneEnums.DroneEffect.LIFE_STEAL,
		DroneEnums.DroneEffect.LIGHTNING_CHANCE,
		DroneEnums.DroneEffect.FREEZE_CHANCE,
		DroneEnums.DroneEffect.AMMO_YIELD,
		DroneEnums.DroneEffect.HITBAR_MULT
	]
}

# the random order of the level effects
var shuffled_effects: Array[Array] = []

# each item is a drone effect
var current_shape: Array[Array]

# each item is an array of dependency co-ordinates
var current_dependencies: Array

# to indicate if we've unlocked any but the base tile
var unlocked_tiles: bool = false

func _init() -> void:
	shuffle_effects()
	generate_shape()

## input: an array of rows where each item is [effect_power, effect_level]
func load_shape(_shape: Array[Array]) -> void:
	pass

func get_effect(x: int, y: int) -> void:
	return

func get_dependencies(x: int, y: int) -> Array:
	return current_dependencies[y][x]

func shuffle_effects() -> void:
	for i in LEVEL_EFFECTS.keys():
		shuffled_effects.append([])
		var order = range(LEVEL_EFFECTS[i].size())
		order.shuffle()
		for effect in order:
			shuffled_effects[i].append(LEVEL_EFFECTS[i][effect])

func generate_shape() -> void:
	var idx = randi_range(0, SHAPES.size() - 1)
	var shape = SHAPES[idx]
	current_shape = []
	current_dependencies = SHAPE_DEPENDENCIES[idx]
	
	for row in range(shape.size()):
		current_shape.append([])
		for column in range(shape[row].size()):
			var new_effect = shuffled_effects[shape[row][column]].pop_front()
			current_shape[row].append(DroneManager.drone_effects.get(new_effect))
			DroneManager.drone_effects.get(new_effect).upgraded.connect(
				func (): unlocked_tiles = true, CONNECT_ONE_SHOT)
