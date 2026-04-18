extends Control

const STATS := [
	"powerup_duration",
	"powerup_spawn_rate",
	"powerup_ultra_chance"
]

const DEFAULT_PANEL := "general"
const UPGRADE_BUTTON_COLOUR := Color("313638")
const ITEM_PANEL = preload("uid://bqy0ly3cn6eod")

const UNLOCK_POWERUP := preload("res://shikoba/assets/unlock_powerup.png")

@onready var item_upgrades := $Powerups/PowerupUpgrades/ItemUpgrades

@onready var general_button := $General/Upgrades/Upgrade/UpgradeButton
@onready var general_display := $General/Upgrades/Upgrade/StatDisplay
@onready var general_upgrades := $General/Upgrades

@onready var unlock_powerup := $Powerups/PowerupUpgrades/ItemUpgrades/UnlockPowerup
@export var replacement_colours: Array[Color]

var current_panel: String

func _ready() -> void:
	_setup_items()
	_setup_general()
	
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha($General/Tab.texture_normal.get_image(), 0.5)
	$General/Tab.texture_click_mask = bitmap
	
	var powerup_bitmap := BitMap.new()
	powerup_bitmap.create_from_image_alpha($Powerups/Tab.texture_normal.get_image(), 0.5)
	$Powerups/Tab.texture_click_mask = powerup_bitmap
	
	change_focus(DEFAULT_PANEL)
	
	var tex_button = unlock_powerup.duplicate() as TextureButton
	(tex_button.get_child(0) as Label).text = StatManager.get_stat("unlocked_powerups").display_cost
	tex_button.mouse_entered.connect(func (): tex_button.material.set_shader_parameter("width", 1))
	tex_button.mouse_exited.connect(func (): tex_button.material.set_shader_parameter("width", 0))
	tex_button.pressed.connect(new_powerup)
	item_upgrades.add_child(tex_button)
	$Powerups/PowerupUpgrades/ItemUpgrades/UnlockPowerup.queue_free()
	unlock_powerup = tex_button
	
func new_powerup() -> void:
	if !StatManager.can_upgrade_stat("unlocked_powerups"):
		return
	
	
	var stat = StatManager.get_stat("unlocked_powerups")
	GameManager.add_mineral.emit(stat.mineral, -stat.cost)
	StatManager.upgrade_stat("unlocked_powerups")
	
	var powerup = StatManager.powerup_order[stat.level - 1]
	
	var new_powerup_panel: PowerupPanel = ITEM_PANEL.instantiate()
	new_powerup_panel.powerup_type = powerup
	item_upgrades.add_child(new_powerup_panel)
	
	stat = StatManager.get_stat("unlocked_powerups")
	unlock_powerup.visible = stat.level < stat.max_level
	(unlock_powerup.get_child(0) as Label).text = stat.display_cost
	item_upgrades.move_child(unlock_powerup, item_upgrades.get_child_count())

func _setup_items() -> void:
	var unlocked_powerups = StatManager.powerup_order.slice(0, StatManager.get_stat("unlocked_powerups").level)
	
	for powerup in unlocked_powerups:
		var new_powerup_panel: PowerupPanel = ITEM_PANEL.instantiate()
		new_powerup_panel.powerup_type = powerup
		item_upgrades.add_child(new_powerup_panel)

func _setup_general() -> void:
	for stat_name in STATS:
		var stat = StatManager.get_stat(stat_name)
		
		var button = general_button.duplicate()
		button.stat_name = stat_name
		button.material = button.material.duplicate()
		button.material.set_shader_parameter("width", 0.)
		
		var stat_display = general_display.duplicate()
		stat_display.upgrade_button = button
		stat_display.texture = load("res://shikoba/assets/general/" + stat.stat_name + ".png")
		
		var new_hbox = HBoxContainer.new()
		new_hbox.add_child(stat_display)
		new_hbox.add_child(button)
		general_upgrades.add_child(new_hbox)
	
	$General/Upgrades/Upgrade.queue_free()

func on_hover(panel: String) -> void:
	if panel == current_panel: return
	match panel:
		"items":
			$Powerups/Tab.material.set_shader_parameter("width", 1)
		"general":
			$General/Tab.material.set_shader_parameter("width", 1)

func off_hover(panel: String, force: bool = false) -> void:
	if panel == current_panel and !force: return
	match panel:
		"items":
			$Powerups/Tab.material.set_shader_parameter("width", 0)
		"general":
			$General/Tab.material.set_shader_parameter("width", 0)

func change_focus(panel: String) -> void:
	if panel == current_panel:
		return
	
	current_panel = panel
	off_hover("items", true)
	off_hover("general", true)
	
	var active
	var inactive
	
	$Powerups/PowerupUpgrades.visible = panel == "items"
	
	if panel == "items":
		active = $Powerups
		inactive = $General
	else:
		active = $General
		inactive = $Powerups
	
	active.z_index = 1
	active.mouse_filter = MOUSE_FILTER_STOP
	inactive.z_index = 0
	inactive.mouse_filter = MOUSE_FILTER_IGNORE
