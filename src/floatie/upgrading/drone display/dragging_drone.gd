extends TextureRect
class_name DraggingDrone

var drone_stats: DroneStats

@onready var level: Label = $Label
@onready var drone: TextureButton = $TextureButton
@onready var matching_type: ColorRect = $MatchingType

var disabled := false
var dragging := false
var offset: Vector2

var matching: bool = false

func _ready() -> void:
	if drone_stats != null:
		setup_stats()
	
	drone.material = drone.material.duplicate()
	
	drone.mouse_entered.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
			drone.material.set_shader_parameter("width", 1))
	
	drone.mouse_exited.connect(
		func ():
			if !dragging:
				GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			drone.material.set_shader_parameter("width", 0)
	)

func setup_stats() -> void:
	drone.texture_normal = DroneManager.get_drone_sprite(drone_stats.drone_type)
	
	level.text = str(drone_stats.level)
	drone.tooltip_text = drone_stats.get_tooltip()

func start_drag() -> void:
	if disabled: return
	offset = global_position - get_global_mouse_position()
	drone.mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameManager.set_mouse_state.emit(Enums.MouseState.DRAG)
	dragging = true

func end_drag() -> void:
	drone.mouse_filter = Control.MOUSE_FILTER_STOP
	dragging = false

func set_matching(m: bool) -> void:
	matching = m
	matching_type.visible = matching

func _process(_d: float) -> void:
	#if matching || dragging:
		#matching_type.material.set_shader_parameter("rotation", )
	
	if dragging:
		global_position = lerp(global_position, get_global_mouse_position() + offset, 0.3)
