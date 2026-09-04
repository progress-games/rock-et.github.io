extends Control

@onready var positions: GridContainer = $Positions/MarginContainer3/Positions
@onready var title: Label = $Details/Title/MarginContainer2/Title
@onready var description: Label = $Details/Description/MarginContainer/Description
@onready var details: VBoxContainer = $Details

@onready var price_panel: HBoxContainer = $Details/Price
@onready var price: Label = $Details/Price/Price/MarginContainer/HBoxContainer/Price
@onready var upgrade: TextureButton = $Details/Price/Upgrade
@onready var unlock: TextureButton = $Details/Price/Unlock

var selected_tile: DroneTile

func _ready() -> void:
	positions.tile_selected.connect(update_details)
	
	upgrade.mouse_entered.connect(func (): hover(upgrade))
	upgrade.mouse_exited.connect(func (): off_hover(upgrade))
	unlock.mouse_entered.connect(func (): hover(unlock))
	unlock.mouse_exited.connect(func (): off_hover(unlock))
	
	unlock.pressed.connect(unlock_tile)

func hover(button: TextureButton) -> void:
	button.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover(button: TextureButton) -> void:
	button.material.set_shader_parameter('width', 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func unlock_tile() -> void:
	positions.unlock_tile(selected_tile)
	update_details(selected_tile)

func update_details(tile: DroneTile) -> void:
	selected_tile = tile
	
	details.scale = Vector2.ONE * 1.5
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(details, "scale", Vector2.ONE, 0.25)
	
	price_panel.visible = tile.shown && \
		tile.drone_effect != DroneEnums.DroneEffect.NOTHING
	
	if !tile.shown:
		title.text = "dunno"
		description.text = "not sure what this tile does"
		return
	
	upgrade.visible = tile.unlocked
	unlock.visible = !tile.unlocked
	
	var effect = DroneManager.drone_effects.get(tile.drone_effect)
	title.text = effect.name
	description.text = effect.description.replace("[VALUE]", str(effect.value))
