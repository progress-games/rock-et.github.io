extends Control

const DRAGGING_OFFSET := Vector2(-1, 2)
const DRAGGING_DRONE = preload("uid://76qblayn7iji")

@export var merging_offsets: Array[Vector2]

@onready var drone_grid: DroneGrid = $Drones/Drones/DroneGrid

# parent: result drone type
@onready var parent_slot: ReferenceRect = $Drones/Merging/MergingInto
@onready var child_slots: Control = $Drones/Merging/Slots

@onready var upgrading: RichTextLabel = $Title/MarginContainer2/MarginContainer/Upgrading
@onready var stat_details: RichTextLabel = $Drones/Stats/MarginContainer2/MarginContainer/RichTextLabel

@onready var start: TextureButton = $StartUpgrade/Start
@onready var progress: Panel = $StartUpgrade/Progress
@onready var progress_bar: Panel = $StartUpgrade/Progress/Progress

@onready var ready_in: Control = $StartUpgrade/ReadyIn
@onready var ready_in_days: Label = $StartUpgrade/ReadyIn/TextureRect/Days

var active_upgrade: bool = false
var upgrading_days_left: int = 0

var currently_dragging: DraggingDrone
var merging: Dictionary[int, DraggingDrone] = {
	0: null,
	1: null,
	2: null,
	3: null,
	4: null
}

var hovering: Control

func _ready() -> void:
	drone_grid.drag_started.connect(start_drag)
	
	setup_slots()
	
	calculate_output()
	
	start.mouse_entered.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
			start.material.set_shader_parameter("width", 1)
	)
	
	start.mouse_exited.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			start.material.set_shader_parameter("width", 0)
	)
	
	start.pressed.connect(start_upgrade)
	
	GameManager.day_changed.connect(
		func (_d):
			if !active_upgrade: return
			upgrading_days_left -= 1
			if upgrading_days_left <= 0:
				end_upgrade()
	)

func setup_slots() -> void:
	parent_slot.set_meta("idx", 0)
	parent_slot.mouse_entered.connect(func (): hover(parent_slot))
	parent_slot.mouse_exited.connect(off_hover)
	
	for i in child_slots.get_child_count():
		var slot = child_slots.get_child(i)
		slot.set_meta("idx", i + 1)
		slot.mouse_entered.connect(func (): hover(slot))
		slot.mouse_exited.connect(off_hover)

func hover(c: Control) -> void:
	#if c.get_meta("idx") > 1: return
	hovering = c

func off_hover() -> void:
	hovering = null

func start_drag(drone: DisplayedDrone) -> void:
	var new_dragging = DRAGGING_DRONE.instantiate() as DraggingDrone
	new_dragging.drone_stats = drone.drone_stats
	add_child(new_dragging)
	
	new_dragging.set_meta("drone", true)
	new_dragging.global_position = drone.global_position
	new_dragging.start_drag()
	
	new_dragging.drone.button_down.connect(func ():
		currently_dragging = new_dragging
		new_dragging.start_drag()
		merging.set(currently_dragging.get_meta('idx'), null)
		calculate_output()
	)
	
	new_dragging.drone.mouse_entered.connect(
		func ():
			if currently_dragging == null || currently_dragging == new_dragging:
				return
			hovering = new_dragging
	)
	
	new_dragging.drone.mouse_exited.connect(
		func ():
			if hovering == new_dragging:
				hovering = null
	)
	
	currently_dragging = new_dragging

func end_drag() -> void:
	calculate_output()
	
	## if we're not hovering over a valid drop location
	if hovering == null:
		currently_dragging.end_drag()
		drone_grid.end_drag(currently_dragging.drone_stats)
		currently_dragging.queue_free()
		return
	
	## if we're hovering over a drone
	if hovering.has_meta("drone"):
		hovering.end_drag()
		#drone_grid.end_drag(hovering.drone_stats)
		var slot_idx = hovering.get_meta("idx")
		
		hovering.queue_free()
		hovering = parent_slot if slot_idx == 0 else child_slots.get_child(slot_idx - 1)
	
	var idx = hovering.get_meta("idx")
	
	## if we're hovering over a spot that currently has a drone
	if merging.get(idx, null) != null:
		var d = merging.get(idx)
		d.end_drag()
		drone_grid.end_drag(d.drone_stats)
		d.queue_free()
	
	currently_dragging.end_drag()
	currently_dragging.set_meta("idx", idx)
	currently_dragging.global_position = hovering.global_position + merging_offsets[idx]
	
	merging.set(idx, currently_dragging)
	
	currently_dragging = null
	calculate_output()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_released() && \
	event.button_index == MOUSE_BUTTON_LEFT && currently_dragging != null:
		end_drag()

# when we're not upgrading anything
func clear_upgrading() -> void:
	start.disabled = true
	stat_details.text = "not upgrading anything"
	
	ready_in.hide()
	
	var regex = RegEx.new()
	regex.compile("[^]]*$")
	upgrading.text = regex.sub(
		upgrading.text, 
		"nothing")

# when we're upgrading something but have nothing to merge into it
func set_upgrading_source() -> void:
	var drone_type = merging[0].drone_stats.drone_type
	
	start.disabled = true
	
	start.show()
	
	var regex = RegEx.new()
	regex.compile("[^]]*$")
	upgrading.text = regex.sub(
		upgrading.text, 
		DroneEnums.DroneType.find_key(drone_type).to_lower())
	
	stat_details.text = "drop another drone in to upgrade"

func get_merging_size() -> int:
	return merging.values().reduce(func (a, x): return a + (1 if x != null else 0), 0)

func get_upgrade_amount() -> int:
	return merging.values().reduce(
		func (a, x):
			return a + (0 if x == null else x.drone_stats.level),
		0
	) - merging[0].drone_stats.level

func calculate_output() -> void:
	if get_merging_size() < 1 or merging[0] == null:
		clear_upgrading()
		return
	
	var merging_parent = merging[0].drone_stats
	
	if get_merging_size() == 1:
		set_upgrading_source()
		return
	
	# amount to upgrade the parent drone
	var upgrades = get_upgrade_amount()
	
	upgrading_days_left = DroneManager.get_upgrade_duration(merging_parent, upgrades)
	
	start.show()
	ready_in.show()
	ready_in_days.text = str(upgrading_days_left)
	
	var regex = RegEx.new()
	regex.compile("[^]]*$")
	upgrading.text = regex.sub(
		upgrading.text, 
		DroneEnums.DroneType.find_key(merging_parent.drone_type).to_lower())
	
	ready_in.show()
	ready_in_days.text = str(upgrading_days_left)
	
	stat_details.text = merging_parent.get_upgrade_details(upgrades)

func start_upgrade() -> void:
	active_upgrade = true
	start.hide()
	progress.show()
	progress_bar.material.set_shader_parameter("progress", 0.)
	
	# lock dragging drones
	merging.values().map(func (x): x.drone.disabled = true)
	merging.values().map(DroneManager.remove_drone)
	drone_grid.disable_drones()
	drone_grid.merging_drones.clear()

func end_upgrade() -> void:
	var merging_parent = merging[0].drone_stats
	var result = DroneManager.get_new_drone(merging_parent.drone_type)
	var upgrades = get_upgrade_amount()
	
	for l in upgrades: DroneManager.upgrade_drone(result)
	
	DroneManager.add_drone(result)
	
	drone_grid.enable_drones()
	drone_grid.arrange_drones()
	progress.hide()
	merging.values().map(func (x): x.queue_free())
	merging = {
		0: null,
		1: null,
		2: null,
		3: null,
		4: null
	}
	calculate_output()
