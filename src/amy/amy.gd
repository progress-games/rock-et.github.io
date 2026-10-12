extends Control

const BASE_UNLOCK = 5
const BASE_UPGRADE := 30

# tier 1 unlocking is 1x the base price
const TIER_UNLOCK_SCALE := [
	1.,
	1.1,
	1.2
]
# tier 1 unlocking is 1.4x base price
const TIER_UPGRADE_SCALE := [
	0.,
	1.,
	1.2
]

const UNLOCK_ADD: int = 30
const UNLOCK_SCALE: float = 1.8

const UPGRADE_ADD: int = 15
const UPGRADE_SCALE: float = 1.2

@onready var positions: GridContainer = $HBoxContainer/Positions/MarginContainer3/Positions
@onready var title: Label = $Details/Title/MarginContainer2/Title
@onready var description: RichTextLabel = $Details/Description/MarginContainer/Description
@onready var details: VBoxContainer = $Details
@onready var next_level_description: RichTextLabel = $Details/Description/MarginContainer/NextLevelDescription

@onready var price_panel: HBoxContainer = $Details/Price
@onready var price: Label = $Details/Price/Price/MarginContainer/HBoxContainer/Price
@onready var upgrade: TextureButton = $Details/Price/Upgrade
@onready var unlock: TextureButton = $Details/Price/Unlock

var selected_tile: DroneTile

var current_unlock: int = BASE_UNLOCK
var current_upgrade: int = BASE_UPGRADE

func _ready() -> void:
	positions.tile_selected.connect(update_details)
	
	upgrade.mouse_entered.connect(func (): hover(upgrade); show_next_level())
	upgrade.mouse_exited.connect(func (): off_hover(upgrade); revert_next_level())
	upgrade.pressed.connect(upgrade_tile)
	unlock.mouse_entered.connect(func (): hover(unlock))
	unlock.mouse_exited.connect(func (): off_hover(unlock))
	
	unlock.pressed.connect(unlock_tile)
	positions.select_tile(positions.tiles[2][2])
	
	StatManager.stat_upgraded.connect(
		func (s):
			if s.stat_name.begins_with("dp_"):
				scale_upgrade_price()
	)
	
	DroneManager.drone_shape.unlocked_tile.connect(func (x, y): 
		if x == 2 && y == 2: return
		scale_unlock_price())

func get_tile_price(tile: DroneTile) -> int:
	var tier = DroneManager.drone_shape.get_effect_tier(tile.drone_effect.effect)
	
	if !tile.unlocked:
		return int(ceil(current_unlock * TIER_UNLOCK_SCALE[tier - 1]))
	
	return int(ceil(current_upgrade * TIER_UPGRADE_SCALE[tier - 1]))

func hover(button: TextureButton) -> void:
	button.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover(button: TextureButton) -> void:
	button.material.set_shader_parameter('width', 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func upgrade_tile() -> void:
	var p = get_tile_price(selected_tile)
	
	if !GameManager.can_afford(p, Enums.Mineral.BAUXITE):
		upgrade.modulate = Color(1, 0, 0)
		var t = create_tween()
		t.tween_property(upgrade, "modulate", Color.WHITE, 0.5)
		return
	
	var drone_effect = DroneEnums.DroneEffect.find_key(selected_tile.drone_effect.effect).to_lower()
	StatManager.upgrade_stat("dp_" + drone_effect)
	
	GameManager.add_mineral.emit(Enums.Mineral.BAUXITE, -p)
		
	update_details(selected_tile)

func unlock_tile() -> void:
	var p = get_tile_price(selected_tile)
	
	if !GameManager.can_afford(p, Enums.Mineral.BAUXITE):
		unlock.modulate = Color(1, 0, 0)
		var t = create_tween()
		t.tween_property(unlock, "modulate", Color.WHITE, 0.5)
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.BAUXITE, -p)
	DroneManager.drone_shape.unlock_tile(selected_tile.x, selected_tile.y)
	update_details(selected_tile)

func scale_unlock_price() -> void:
	current_unlock = int(ceil((current_unlock + UNLOCK_ADD) * UNLOCK_SCALE))
	price.text = str(get_tile_price(selected_tile))

func scale_upgrade_price() -> void:
	current_upgrade = int(ceil((current_upgrade + UPGRADE_ADD) * UPGRADE_SCALE))
	price.text = str(get_tile_price(selected_tile))

func update_details(tile: DroneTile) -> void:
	selected_tile = tile
	
	details.scale = Vector2.ONE * 1.5
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(details, "scale", Vector2.ONE, 0.25)
	
	price_panel.visible = tile.shown && \
		(tile.drone_effect.effect != DroneEnums.DroneEffect.NOTHING || !tile.unlocked)
	
	if !tile.shown:
		title.text = "dunno"
		description.text = "not sure what this tile does"
		return
	
	price.text = str(get_tile_price(tile))
	upgrade.visible = tile.unlocked
	unlock.visible = !tile.unlocked
	
	title.text = tile.drone_effect.name
	description.text = tile.drone_effect.get_description()
	next_level_description.text = tile.drone_effect.get_description(true)

func show_next_level() -> void:
	description.modulate = Color.TRANSPARENT
	next_level_description.modulate = Color.WHITE

func revert_next_level() -> void:
	description.modulate = Color.WHITE
	next_level_description.modulate = Color.TRANSPARENT
