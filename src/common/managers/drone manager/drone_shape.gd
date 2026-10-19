extends Object
class_name DroneShape

const SHAPES: Array[Array] = [
	[
		[1, 3, 3, 3, 1],
		[3, 2, 1, 2, 3],
		[3, 1, 1, 1, 3],
		[3, 2, 1, 2, 3],
		[1, 3, 3, 3, 1]
	]
]

# array of x and y positions that need to be unlocked to unlock this tile
const SHAPE_DEPENDENCIES: Array[Array] = [
	[
		[    [[1, 1]],     [[1, 1]], [[1, 0], [3, 0]], [[3, 1]],    [[3, 1]]],
		[    [[1, 1]],     [[2, 2]],     [[2, 2]],     [[2, 2]],    [[3, 1]]],
		[[[0, 1], [0, 3]], [[2, 2]],        [],        [[2, 2]], [[4, 1], [4, 3]]],
		[    [[1, 3]],     [[2, 2]],     [[2, 2]],     [[2, 2]],   [[3, 3]]],
		[    [[1, 3]],     [[1, 3]], [[1, 4], [3, 4]], [[3, 3]],   [[3, 3]]]
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
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
		DroneEnums.DroneEffect.NOTHING,
	],
	2: [
		DroneEnums.DroneEffect.FIRE_RATE, 
		DroneEnums.DroneEffect.DAMAGE, 
		DroneEnums.DroneEffect.PIERCE, 
		DroneEnums.DroneEffect.AMMO_CAPACITY
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
		DroneEnums.DroneEffect.GHOST_AMMO,
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
#var unlocked_tiles: bool = false

signal unlocked_tile(x: int, y: int)
signal shape_updated

func _init() -> void:
	shuffle_effects()
	generate_shape()
	
	unlock_tile.call_deferred(2, 1)
	unlock_tile.call_deferred(2, 3)
	unlock_tile.call_deferred(3, 2)
	unlock_tile.call_deferred(1, 2)

## input: an array of rows where each item is [effect_type, unlocked boolean]
func load_shape(_shape: Array[Array]) -> void:
	current_shape = _shape
	shape_updated.emit()
	for y in range(current_shape.size()):
		for x in range(current_shape[y].size()):
			if current_shape[y][x][1]:
				unlock_tile(x, y)

func get_effect(x: int, y: int) -> DroneEffect:
	return current_shape[y][x][0]

func get_effect_tier(effect: DroneEnums.DroneEffect) -> int:
	var a = 0
	while !(effect in LEVEL_EFFECTS[a]):
		a += 1
	
	return a

func get_dependencies(x: int, y: int) -> Array:
	return current_dependencies[y][x]

func shuffle_effects() -> void:
	for i in LEVEL_EFFECTS.keys():
		shuffled_effects.append([])
		var order = range(LEVEL_EFFECTS[i].size())
		order.shuffle()
		for effect in order:
			shuffled_effects[i].append(LEVEL_EFFECTS[i][effect])

func unlock_tile(x: int, y: int) -> void:
	current_shape[y][x][1] = true
	unlocked_tile.emit(x, y)

func generate_shape() -> void:
	var idx = randi_range(0, SHAPES.size() - 1)
	var shape = SHAPES[idx]
	current_shape = []
	current_dependencies = SHAPE_DEPENDENCIES[idx]
	
	for row in range(shape.size()):
		current_shape.append([])
		for column in range(shape[row].size()):
			var new_effect = shuffled_effects[shape[row][column]].pop_front()
			current_shape[row].append([DroneManager.drone_effects.get(new_effect), false])
