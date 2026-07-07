extends TextureButton
class_name ExchangeRateButton


const DECREASING = preload("uid://jpcwiwo3qf2c")
const INCREASING = preload("uid://ddj1eoyujc8o4")

const LOCKED_DARK = Color(0.18, 0.133, 0.184, 1.0);
const LOCKED_MID = Color(0.384, 0.333, 0.396, 1.0)

@onready var mineral_texture: TextureRect = $HBoxContainer/Mineral
@onready var rate: Label = $HBoxContainer/Rate
@onready var arrow: TextureRect = $HBoxContainer/Arrow
@onready var locked: TextureRect = $HBoxContainer/Locked

var is_locked = false
var mineral: Enums.Mineral
var previous_rate: float

func _ready() -> void:
	material = material.duplicate()
	mineral_texture.material = mineral_texture.material.duplicate()
	mouse_entered.connect(func (): 
		material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	)
	mouse_exited.connect(func (): 
		material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	)

func set_mineral(m: Enums.Mineral) -> void:
	mineral = m
	var mineral_data = GameManager.mineral_data[m]
	
	mineral_texture.texture = mineral_data.texture
	
	if GameManager.player.has_discovered_mineral(m): 
		unlock()
	else: 
		lock()
		GameManager.player.mineral_discovered.connect(func (_m): if m == _m: unlock())

func lock() -> void:
	is_locked = true
	rate.visible = false
	arrow.visible = false
	locked.visible = true
	mineral_texture.material.set_shader_parameter("flash_value", 1)
	material.set_shader_parameter("replacement_colors", [LOCKED_DARK, LOCKED_MID])

func unlock() -> void:
	is_locked = false
	rate.visible = true
	arrow.visible = true
	locked.visible = false
	mineral_texture.material.set_shader_parameter("flash_value", 0)
	var mineral_data = GameManager.mineral_data[mineral]
	material.set_shader_parameter("replacement_colors", [mineral_data.dark_colour, mineral_data.mid_colour])

func update_value(new_rate: float) -> void:
	if is_locked: return
	rate.text = str(round(new_rate * 10) / 10)
	arrow.texture = INCREASING if previous_rate < new_rate else DECREASING
	previous_rate = new_rate
