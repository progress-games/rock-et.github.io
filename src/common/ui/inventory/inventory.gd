extends VBoxContainer

const DEFAULT_STATE := Enums.InventoryState.INTERACTIVE
const DEFAULT_MINERAL := Enums.Mineral.AMETHYST
const ROW := preload("res://common/ui/inventory/row.tscn")
const OFFSET := Vector2(-160, -90)

var state: Enums.InventoryState
var faded: bool
var location: Vector2
var minerals: Array[Enums.Mineral] = []
var interactive_order: Array[Enums.Mineral] = [Enums.Mineral.AMETHYST]

"""
How to use the inventory system:

Use GameManager.set_inventory(state, *faded, *position) to set the state
Use GameManager.clear_inventory() to purge all items
Use GameManager.show_mineral(mineral) to add a new row for that mineral
"""

func _ready() -> void:
	GameManager.set_inventory.connect(set_state)
	GameManager.clear_inventory.connect(clear_inventory)
	GameManager.show_mineral.connect(create_row)
	
	# add new mineral to interactive order
	GameManager.player.mineral_discovered.connect(func (m): 
		if !interactive_order.has(m): interactive_order.append(m))
	
	# reset inventory
	GameManager.state_changed.connect(func (s): if s == Enums.State.HOME: reset_inventory())
	
	# show/hide
	GameManager.show_inventory.connect(func (): visible = true)
	GameManager.hide_inventory.connect(func (): visible = false)
	
	GameManager.show_inventory.connect(print_stack)
	GameManager.hide_inventory.connect(print_stack)
	
	# if we're in mission, create a new row for every new mineral
	GameManager.add_mineral.connect(func (m, a):
		if state == Enums.InventoryState.MISSION:
			create_row(m)
	)
	
	reset_inventory()

func reset_inventory() -> void:
	set_state(DEFAULT_STATE)
	clear_inventory()
	create_row(DEFAULT_MINERAL)
	navigate()

func create_row(mineral: Enums.Mineral) -> void:
	if minerals.has(mineral): 
		return
	
	if state == Enums.InventoryState.INTERACTIVE:
		clear_inventory()
	
	minerals.append(mineral)
	
	var row = ROW.instantiate()
	row.top = minerals.size() == 1
	row.mineral = mineral
	row.inventory = state
	add_child(row)
	if !row.top:
		move_child(row, 2)
	else:
		move_child(row, 0)
	
	set_faded()

func clear_inventory() -> void:
	minerals.clear()
	
	for child in get_children():
		if child.has_meta("row"):
			remove_child(child)
			child.queue_free()

func set_state(_state: Enums.InventoryState, _faded: bool = false, _location: Vector2 = Vector2(-2, -2)) -> void:
	if state == Enums.InventoryState.MISSION and _state != Enums.InventoryState.INTERACTIVE: return
	state = _state
	location = _location
	mouse_filter = Control.MOUSE_FILTER_STOP if state == Enums.InventoryState.INTERACTIVE else Control.MOUSE_FILTER_IGNORE
	
	$Navigate.visible = state == Enums.InventoryState.INTERACTIVE && interactive_order.size() > 1
	position = OFFSET + location
	set_faded(_faded)

func navigate(direction: int = 0) -> void:
	var idx = interactive_order.find(minerals[0])
	var new_idx = (idx + direction) % interactive_order.size()
	var new_mineral = interactive_order[new_idx]
	
	clear_inventory()
	create_row(new_mineral)
	set_faded(faded)
	
	var colours = [
		GameManager.mineral_data[new_mineral].light_colour,
		GameManager.mineral_data[new_mineral].mid_colour,
		GameManager.mineral_data[new_mineral].dark_colour
	]
	$Navigate/Left.material.set_shader_parameter("replacement_colors", colours)
	$Navigate/Right.material.set_shader_parameter("replacement_colors", colours)

func set_faded(_faded: bool = false) -> void:
	faded = _faded
	modulate = Color(1, 1, 1, 0.4) if faded else Color(1, 1, 1, 1)
	
	for child in get_children():
		if child.has_method("fade"):
			child.fade(faded)
