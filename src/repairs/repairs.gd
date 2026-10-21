extends Control

const TOTAL_SHIPS := 10
const SHIP_DIM := 64

const LEVEL_DESCRIPTIONS := [
	"repair right leg and readjust orientation",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
]

@onready var current_ship: TextureRect = $HBoxContainer/TextureRect/TextureRect
@onready var next_ship: TextureRect = $HBoxContainer/TextureRect3/TextureRect2

@onready var price: RichTextLabel = $HBoxContainer2/MarginContainer/MarginContainer2/RichTextLabel
@onready var description: Label = $HBoxContainer2/MarginContainer2/MarginContainer/Label

@onready var repair_button: TextureButton = $Repair

func _ready() -> void:
	set_ship_sprite()
	
	repair_button.mouse_entered.connect(on_hover.bind(repair_button))
	repair_button.mouse_exited.connect(off_hover.bind(repair_button))
	repair_button.pressed.connect(repair_ship)

func on_hover(b: Control) -> void:
	b.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover(b: Control) -> void:
	b.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func repair_ship() -> void:
	StatManager.upgrade_stat("ship_health")
	set_ship_sprite()

func set_ship_sprite() -> void:
	var ship_level := StatManager.get_stat("ship_health").level
	
	current_ship.texture.region = Rect2(
		(TOTAL_SHIPS - ship_level) * SHIP_DIM, 0,
		SHIP_DIM, SHIP_DIM
	)
	next_ship.texture.region = Rect2(
		(TOTAL_SHIPS - ship_level - 1) * SHIP_DIM, 0,
		SHIP_DIM, SHIP_DIM
	)
	
	description.text = LEVEL_DESCRIPTIONS[ship_level - 1]
	price.text = StatManager.get_stat("ship_health").display_cost + " [img]res://common/minerals/beryl.png[/img]"
