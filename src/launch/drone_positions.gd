extends Control

const DRAGGING_OFFSET = Vector2(2, 2)
const DRAGGING_DRONE = preload("uid://76qblayn7iji")

@onready var launch: TextureButton = $"../Launch"
@onready var close_tab: TextureButton = $"../../CloseTab"

@onready var positions: DronePositions = $HBoxContainer/MarginContainer/MarginContainer2/DronePositions/Positions
@onready var drone_grid: DroneGrid = $HBoxContainer/MarginContainer/MarginContainer2/DronePositions/DroneGrid

var active_dragging: Array[DraggingDrone]
var currently_dragging: DraggingDrone
var hovering: DroneTile

var equipped: Dictionary[DroneTile, DraggingDrone] = {}

func _ready() -> void:
	visibility_changed.connect(
		func ():
			if visible:
				launch.position = Vector2(8, 122)
				close_tab.position = Vector2(280, 0)
			else:
				launch.position = Vector2(0, 119)
				close_tab.position = Vector2(190, 9)
	)
	
	GameManager.state_changed.connect(
		func (s):
			if s == Enums.State.MISSION:
				equip_drones()
			elif s == Enums.State.LAUNCH:
				positions.check_for_upgrades()
	)
	
	drone_grid.drag_started.connect(start_drag)
	positions.entered_tile.connect(hover)
	positions.exited_tile.connect(off_hover)

func equip_drones() -> void:
	for tile in equipped.keys():
		var new_position = DronePosition.new()
		# because drone pos is from centre and coords are from top right
		new_position.x = tile.coords.x - 2
		new_position.y = tile.coords.y - 2
		new_position.drone_stats = equipped.get(tile).drone_stats
		DroneManager.equipped_drones.append(new_position)

func hover(tile: DroneTile) -> void:
	if !tile.unlocked: return
	positions.select_tile(tile)
	hovering = tile

func off_hover(tile: DroneTile) -> void:
	if !tile.unlocked: return
	tile.deselect()
	hovering = null

func start_drag(drone: DisplayedDrone) -> void:
	var new_dragging = DRAGGING_DRONE.instantiate() as DraggingDrone
	new_dragging.drone_stats = drone.drone_stats
	add_child(new_dragging)
	
	new_dragging.global_position = drone.global_position
	new_dragging.start_drag()
	new_dragging.drone.button_down.connect(func ():
		currently_dragging = new_dragging
		new_dragging.start_drag()
	)
	
	# replace this drone
	new_dragging.drone.mouse_entered.connect(
		func ():
			if currently_dragging == null || currently_dragging == new_dragging:
				return
			hovering = equipped.find_key(new_dragging)
	)
	
	new_dragging.drone.mouse_exited.connect(func (): hovering = null)
	
	currently_dragging = new_dragging
	active_dragging.append(currently_dragging)

func end_drag() -> void:
	if currently_dragging == null: 
		return
	
	if hovering == null:
		currently_dragging.end_drag()
		drone_grid.end_drag(currently_dragging.drone_stats)
		active_dragging.erase(currently_dragging)
		currently_dragging.queue_free()
		return
	
	if equipped.get(hovering) != currently_dragging && equipped.get(hovering) != null:
		var replacing = equipped.get(hovering)
		drone_grid.end_drag(replacing.drone_stats)
		active_dragging.erase(replacing)
		replacing.queue_free()
	
	currently_dragging.end_drag()
	currently_dragging.global_position = hovering.global_position + DRAGGING_OFFSET
	equipped.set(hovering, currently_dragging)
	currently_dragging = null

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_released() && \
	event.button_index == MOUSE_BUTTON_LEFT && currently_dragging != null:
		end_drag()
