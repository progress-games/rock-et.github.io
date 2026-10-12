extends GridContainer
class_name DronePositions

const TILE = preload("uid://b5u8q3me0soia")

@export var hide_locked: bool = false

var shuffled_effects: Dictionary[int, Array]

var selected_tile: DroneTile

var tiles: Array[Array]

signal tile_selected(tile: DroneTile)

signal entered_tile(tile: DroneTile)
signal exited_tile(tile: DroneTile)

func _ready() -> void:
	setup_shape()
	DroneManager.drone_shape.shape_updated.connect(setup_shape)
	DroneManager.drone_shape.unlocked_tile.connect(func (x, y): unlock_tile(tiles[y][x]))

func unlock_tile(tile: DroneTile) -> void:
	tile.set_state(DroneTile.State.UNLOCKED)
	tile_selected.emit(tile)
	display_tiles()

func select_tile(tile: DroneTile) -> void:
	if selected_tile != null:
		selected_tile.deselect()
	selected_tile = tile
	tile.select()
	tile_selected.emit(tile)

func get_tile_state(tile: DroneTile) -> DroneTile.State:
	if tile.unlocked: 
		return DroneTile.State.UNLOCKED
	
	var d = DroneManager.drone_shape.get_dependencies(tile.x, tile.y)
	
	if !hide_locked && (d.size() <= 0 || d.any(func (p): return tiles[p[1]][p[0]].unlocked)):
		return DroneTile.State.SHOWN
	
	return DroneTile.State.HIDDEN

func display_tiles() -> void:
	get_children().map(func (x): x.show())
	
	for row in tiles:
		for tile in row:
			tile.set_state(get_tile_state(tile), hide_locked)
	
	var hide_left = tiles.all(
		func (row): return row[0].state == DroneTile.State.HIDDEN || row[0].disabled
	)
	var hide_right = tiles.all(
		func (row): return row[4].state == DroneTile.State.HIDDEN || row[4].disabled
	)
	var hide_top = tiles[0].all(
		func (tile): return tile.state == DroneTile.State.HIDDEN || tile.disabled
	)
	var hide_bottom = tiles[4].all(
		func (tile): return tile.state == DroneTile.State.HIDDEN || tile.disabled
	)
	
	# fyi empty tiles are disabled
	tiles.map(func (row): 
		if hide_left: row[0].hide()
		if hide_right: row[4].hide())
	
	tiles[0].map(func (t): if hide_top: t.hide())
	tiles[4].map(func (t): if hide_bottom: t.hide())
	
	columns = 5 - int(hide_left) - int(hide_right)

func setup_shape() -> void:
	var shape = DroneManager.drone_shape.current_shape
	tiles.clear()
	get_children().map(func (x): x.queue_free())
	
	for y in range(shape.size()):
		var tile_row = []
		for x in range(shape[y].size()):
			var new_tile = TILE.instantiate() as DroneTile
			add_child(new_tile)
			new_tile.set_effect(DroneManager.drone_shape.get_effect(x, y))
			new_tile.coords = Vector2(x, y)
			new_tile.mouse_entered.connect(func (): entered_tile.emit(new_tile))
			new_tile.mouse_exited.connect(func (): exited_tile.emit(new_tile))
			new_tile.pressed.connect(func (): select_tile(new_tile))
			tile_row.append(new_tile)
		tiles.append(tile_row)
	
	display_tiles()
