extends Control

const PANEL = preload("uid://hqpuwsrmnsif")
const PANEL_OUTLINE = preload("uid://em3g2k08gpjl")
const UPGRADE_COLOUR = Color(0.569, 0.859, 0.412, 1.0)
const FUEL_GAIN = preload("uid://cajp5p6ymnyjt")

@onready var boost: NinePatchRect = $Boost
@onready var boost_display: BoostDisplay = $Boost/BoostDisplay
@onready var boost_price: Label = $Boost/Price

@onready var armour_stat_display: StatDisplay = $Armour/StatDisplay
@onready var upgrade_button: UpgradeButton = $Armour/UpgradeButton

@onready var armour_progress: MarginContainer = $ArmourProgress
@onready var armour_progress_bars: Array[ColorRect] = [
	$ArmourProgress/MarginContainer2/HBoxContainer/ColorRect, 
	$ArmourProgress/MarginContainer2/HBoxContainer/ColorRect2, 
	$ArmourProgress/MarginContainer2/HBoxContainer/ColorRect3, 
	$ArmourProgress/MarginContainer2/HBoxContainer/ColorRect4, 
	$ArmourProgress/MarginContainer2/HBoxContainer/ColorRect5
]

var armour_unlocked := false

func _ready() -> void:
	boost.mouse_entered.connect(on_boost_hover)
	boost.mouse_exited.connect(off_boost_hover)
	boost.gui_input.connect(func (e): if is_mouse(e): boost_upgraded())
	
	StatManager.stat_upgraded.connect(func (s: Stat): 
		if s.stat_name == "armour":
			upgrade_armour())
	
	update_boost_price()

func upgrade_armour() -> void:
	if armour_unlocked: return
	
	var s = StatManager.get_stat("armour")
	
	if s.level > armour_progress_bars.size():
		armour_stat_display.texture = FUEL_GAIN
		upgrade_button.change_stat("armour")
		armour_progress_bars.map(func (x): x.color = UPGRADE_COLOUR)
		armour_unlocked = true
		return
	
	armour_progress_bars[s.level - 2].color = UPGRADE_COLOUR

func boost_upgraded() -> void:
	if !StatManager.can_upgrade_stat("boost_distance"):
		return
	
	StatManager.upgrade_stat("boost_distance")
	update_boost_price()

func update_boost_price() -> void:
	boost_price.text = StatManager.get_stat("boost_distance").display_cost

func on_boost_hover() -> void:
	boost.texture = PANEL_OUTLINE
	boost.patch_margin_bottom = 6
	boost.patch_margin_top = 6
	boost.patch_margin_left = 6
	boost.patch_margin_right = 6
	
	boost_display.set_mineral_colours(true)

func off_boost_hover() -> void:
	boost.texture = PANEL
	boost.patch_margin_bottom = 5
	boost.patch_margin_top = 5
	boost.patch_margin_left = 5
	boost.patch_margin_right = 5
	
	boost_display.set_mineral_colours()

func is_mouse(e: InputEvent) -> bool:
	return e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT
