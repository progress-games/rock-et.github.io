extends ScrollContainer
class_name DroneGrid

const DISPLAYED_DRONE = preload("uid://y07uw760dge")

@onready var grid_container: GridContainer = $GridContainer


"""
thought a lot about this and is best solution for now probably
stores all drones that are currently being merged so we can keep track of quantities
"""
var merging_drones: Dictionary[DroneEnums.DroneType, Dictionary]

var disabled: bool = false

signal drag_started(drone: DisplayedDrone)

func _ready() -> void:
	arrange_drones()
	
	DroneManager.drone_added.connect(arrange_drones)

func remove_merge(drone: DroneStats) -> void:
	merging_drones[drone.drone_type][drone.level] -= 1

func add_merge(drone: DroneStats) -> void:
	var drone_type = drone.drone_type
	var level = drone.level
	
	merging_drones.set(drone_type, merging_drones.get(drone_type, {}))
	merging_drones[drone_type].set(level, merging_drones[drone_type].get(level, 0) + 1)

func get_merging_amount(drone: DroneStats) -> int:
	var drone_type = drone.drone_type
	var level = drone.level
	if !merging_drones.has(drone_type): 
		return 0
	if !merging_drones[drone_type].has(level): 
		return 0
	
	return merging_drones[drone_type][level]

func arrange_drones() -> void:
	grid_container.get_children().map(func (x): x.queue_free())
	
	for drone in DroneManager.get_unique_drones():
		if DroneManager.get_quantity(drone) - get_merging_amount(drone) <= 0: 
			continue
		var new = DISPLAYED_DRONE.instantiate() as DisplayedDrone
		new.drone_stats = drone
		new.quantity = DroneManager.get_quantity(drone) - get_merging_amount(drone)
		grid_container.add_child(new)
		new.drone.disabled = disabled
		new.drone.button_down.connect(func (): start_drag(new))

func start_drag(drone: DisplayedDrone) -> void:
	drag_started.emit(drone)
	add_merge(drone.drone_stats)
	arrange_drones()

func end_drag(drone: DroneStats) -> void:
	remove_merge(drone)
	arrange_drones()

func disable_drones() -> void:
	disabled = true
	grid_container.get_children().map(func (x): x.drone.disabled = true)

func enable_drones() -> void:
	disabled = false
	grid_container.get_children().map(func (x): x.drone.disabled = false)
