extends TextureRect
class_name DisplayedDrone

@onready var quantity_label: Label = $Quantity
@onready var level: Label = $Level
@onready var drone: TextureButton = $Drone

var quantity: int
var drone_stats: DroneStats

func _ready() -> void:
	setup_details()
	
	drone.material = drone.material.duplicate()
	
	drone.mouse_entered.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
			drone.material.set_shader_parameter("width", 1)
	)
	
	drone.mouse_exited.connect(
		func ():
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			drone.material.set_shader_parameter("width", 0)
	)

func setup_details() -> void:
	drone.texture_normal = DroneManager.get_drone_sprite(drone_stats.drone_type)
	
	level.text = str(drone_stats.level)
	quantity_label.text = "x" + str(quantity)
	drone.tooltip_text = \
		DroneEnums.DroneType.find_key(drone_stats.drone_type).to_lower().replace("_", " ")
