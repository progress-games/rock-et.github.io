extends GridContainer

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

const TILE = preload("uid://b5u8q3me0soia")

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

var shuffled_effects: Dictionary[int, Array]

var current_dependencies: Array
var current_shape: Array
var selected_tile: DroneTile

var tiles: Array[Array]

signal tile_selected(tile: DroneTile)

func _ready() -> void:
	shuffle_effects()
	setup_shape()
	unlock_tile(tiles[2][2])

func shuffle_effects() -> void:
	for i in LEVEL_EFFECTS.keys():
		shuffled_effects.set(i, [])
		var order = range(LEVEL_EFFECTS[i].size())
		order.shuffle()
		for effect in order:
			shuffled_effects[i].append(LEVEL_EFFECTS[i][effect])

func unlock_tile(tile: DroneTile) -> void:
	tile.set_state(DroneTile.State.UNLOCKED)
	tile_selected.emit(tile)
	check_dependencies()

func select_tile(tile: DroneTile) -> void:
	if selected_tile != null:
		selected_tile.deselect()
	selected_tile = tile
	tile.select()
	tile_selected.emit(tile)

func check_dependencies() -> void:
	for y in range(current_dependencies.size()):
		for x in range(current_dependencies[y].size()):
			tiles[y][x].set_state(get_tile_state(x, y))

func get_tile_state(x: int, y: int) -> DroneTile.State:
	if tiles[y][x].unlocked: 
		return DroneTile.State.UNLOCKED
	
	var d = current_dependencies[y][x]
	
	if d.size() <= 0 || d.all(func (p): return tiles[p[1]][p[0]].unlocked):
		return DroneTile.State.SHOWN
	
	return DroneTile.State.HIDDEN

func setup_shape() -> void:
	var idx = randi_range(0, SHAPES.size() - 1)
	current_shape = SHAPES[idx]
	current_dependencies = SHAPE_DEPENDENCIES[idx]
	tiles = []
	
	for y in range(current_shape.size()):
		var tile_row = []
		for x in range(current_shape[y].size()):
			var new_tile = TILE.instantiate() as DroneTile
			add_child(new_tile)
			var e = shuffled_effects[current_shape[y][x]].pop_front()
			#print_debug(DroneEnums.DroneEffect.find_key(e))
			new_tile.set_effect(e)
			new_tile.pressed.connect(func (): select_tile(new_tile))
			tile_row.append(new_tile)
		tiles.append(tile_row)
