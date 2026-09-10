extends GridContainer
class_name DronePositions

const TILE = preload("uid://b5u8q3me0soia")

var shuffled_effects: Dictionary[int, Array]

var selected_tile: DroneTile

var tiles: Array[Array]

signal tile_selected(tile: DroneTile)

signal entered_tile(tile: DroneTile)
signal exited_tile(tile: DroneTile)

func _ready() -> void:
	setup_shape()
	unlock_tile(tiles[2][2])

func unlock_tile(tile: DroneTile) -> void:
	tile.drone_effect.upgrade()
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
	var d = DroneManager.drone_shape.current_dependencies
	for y in range(d.size()):
		for x in range(d[y].size()):
			tiles[y][x].set_state(get_tile_state(x, y))

func get_tile_state(x: int, y: int) -> DroneTile.State:
	if tiles[y][x].unlocked: 
		return DroneTile.State.UNLOCKED
	
	var d = DroneManager.drone_shape.get_dependencies(x, y)
	
	if d.size() <= 0 || d.all(func (p): return tiles[p[1]][p[0]].unlocked):
		return DroneTile.State.SHOWN
	
	return DroneTile.State.HIDDEN

func check_for_upgrades() -> void:
	for tile_row in tiles:
		for tile in tile_row:
			tile.unlocked = tile.drone_effect.level > 0
	
	check_dependencies()

func setup_shape() -> void:
	var shape = DroneManager.drone_shape.current_shape
	tiles = []
	
	for y in range(shape.size()):
		var tile_row = []
		for x in range(shape[y].size()):
			var new_tile = TILE.instantiate() as DroneTile
			add_child(new_tile)
			new_tile.set_effect(shape[y][x])
			new_tile.coords = Vector2(x, y)
			new_tile.mouse_entered.connect(func (): entered_tile.emit(new_tile))
			new_tile.mouse_exited.connect(func (): exited_tile.emit(new_tile))
			new_tile.pressed.connect(func (): select_tile(new_tile))
			tile_row.append(new_tile)
		tiles.append(tile_row)
	
	check_for_upgrades()
