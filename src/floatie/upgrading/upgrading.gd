extends Control

const DRAGGING_OFFSET := Vector2(-1, 2)
const DRAGGING_DRONE = preload("uid://76qblayn7iji")

@onready var drone_grid: DroneGrid = $DroneGrid
@onready var slots: VBoxContainer = $Merging/Slots
@onready var result: DraggingDrone = $Merging/Result/DraggingDrone
@onready var upgrading: RichTextLabel = $Title/MarginContainer2/MarginContainer/Upgrading
@onready var upgrading_container: HBoxContainer = $Title
@onready var stat_details: RichTextLabel = $Stats/MarginContainer2/MarginContainer/RichTextLabel
@onready var stat_container: VBoxContainer = $Stats
@onready var start: TextureButton = $Start
@onready var progress: Panel = $Progress
@onready var progress_bar: Panel = $Progress/Progress

@onready var ready_in: Control = $ReadyIn
@onready var ready_in_days: Label = $ReadyIn/TextureRect/Days

var active_dragging: Array[DraggingDrone]
var currently_dragging: DraggingDrone

var active_upgrade: bool = false
var upgrading_days_left: int = 0

var merging: Dictionary[int, DroneStats] = {
	0: null,
	1: null,
	2: null,
	3: null
}

var hovering: Control

func _ready() -> void:
	drone_grid.drag_started.connect(start_drag)
	
	for i in slots.get_child_count():
		var slot = slots.get_child(i)
		slot.set_meta("idx", i)
		slot.mouse_entered.connect(func (): hover(slot))
		slot.mouse_exited.connect(off_hover)
	
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

func start_upgrade() -> void:
	active_upgrade = true
	start.hide()
	progress.show()
	progress_bar.material.set_shader_parameter("progress", 0.)
	
	# lock dragging drones
	active_dragging.map(func (x): x.drone.disabled = true)
	merging.values().map(DroneManager.remove_drone)
	drone_grid.disable_drones()
	drone_grid.merging_drones.clear()

func end_upgrade() -> void:
	active_dragging.map(func (x): x.queue_free())
	active_dragging.clear()
	DroneManager.add_drone(result.drone_stats)
	drone_grid.enable_drones()
	drone_grid.arrange_drones()
	progress.hide()
	merging.clear()
	calculate_output()

func hover(c: Control) -> void:
	calculate_output()
	
	if c.get_meta("idx") > 1: return
	hovering = c

func off_hover() -> void:
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
		merging.erase(currently_dragging.get_meta('idx'))
		calculate_output()
	)
	
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
	
	currently_dragging.end_drag()
	currently_dragging.global_position = hovering.global_position + DRAGGING_OFFSET
	
	var idx = hovering.get_meta("idx")
	currently_dragging.set_meta("idx", idx)
	merging.set(idx, currently_dragging.drone_stats)
	
	currently_dragging = null
	
	calculate_output()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.is_released() && \
	event.button_index == MOUSE_BUTTON_LEFT && currently_dragging != null:
		end_drag()

func calculate_output() -> void:
	var first_idx = 0
	while first_idx < merging.size() && merging.get(first_idx) == null:
		first_idx += 1
	
	# hide if only 1 item merging
	if first_idx == merging.size(): 
		result.hide()
		upgrading_container.hide()
		stat_container.hide()
		start.hide()
		ready_in.hide()
		return
	
	result.show()
	
	var upgrades = merging.values().reduce(
		func (a, x):
			return a + (0 if x == null else x.level),
		0
	) - 1
	
	result.drone_stats = DroneManager.get_new_drone( merging[first_idx].drone_type)
	for l in upgrades: DroneManager.upgrade_drone(result.drone_stats)
	result.setup_stats()
	
	if upgrades == 0:
		upgrading_container.hide()
		stat_container.hide()
		start.hide()
		ready_in.hide()
		return
	
	upgrading_days_left = DroneManager.get_upgrade_duration(result.drone_stats, upgrades)
	
	upgrading_container.show()
	stat_container.show()
	start.show()
	ready_in.show()
	ready_in_days.text = str(upgrading_days_left)
	
	var regex = RegEx.new()
	regex.compile("[^]]*$")
	upgrading.text = regex.sub(
		upgrading.text, 
		DroneEnums.DroneType.find_key(result.drone_stats.drone_type).to_lower())
	
	stat_details.text = merging.get(first_idx).get_upgrade_details(upgrades)
