extends Control

const STATS := [
	"powerup_duration",
	"powerup_spawn_rate",
	"powerup_ultra_chance"
]

const DEFAULT_PANEL := "general"

@onready var item_upgrades := $Powerups/PowerupUpgrades/ItemUpgrades
@onready var item_panel := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel
@onready var item_stat := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel/StatDisplay
@onready var item_button := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel/UpgradeButton

@onready var general_button := $General/Upgrades/Upgrade/UpgradeButton
@onready var general_display := $General/Upgrades/Upgrade/StatDisplay
@onready var general_upgrades := $General/Upgrades

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

func _setup_items() -> void:
	for powerup in GameManager.powerup_data.keys():
		var colours = GameManager.powerup_data[powerup].colours
		
		var new_panel = item_panel.duplicate()
		new_panel.get_children().map(func (x): x.queue_free())
		new_panel.material = new_panel.material.duplicate()
		new_panel.material.set_shader_parameter("replacement_colors", [colours.dark, colours.mid, colours.light, colours.shine])
		
		var upgrade_button = item_button.duplicate()
		upgrade_button.stat_name = Powerup.PowerupType.find_key(powerup).to_lower()
		upgrade_button.text_colour = colours.dark
		upgrade_button.bg_colour = colours.mid
		upgrade_button.material = upgrade_button.material.duplicate()
		upgrade_button.material.set_shader_parameter("replacement_colors", [colours.dark, colours.mid, colours.light, colours.shine])
		upgrade_button.material.set_shader_parameter("width", 0.)
		
		var stat_display = item_stat.duplicate()
		stat_display.upgrade_button = upgrade_button
		stat_display.texture = GameManager.powerup_data[powerup].big
		stat_display.font_colour = colours.dark
		stat_display.outline_colour = colours.mid
		stat_display.upgrade_font_colour = colours.shine
		stat_display.upgrade_outline_colour = colours.mid
		stat_display.upgrade_arrow_colour = colours.shine
		
		item_upgrades.add_child(new_panel)
		new_panel.add_child(stat_display)
		new_panel.add_child(upgrade_button)
	
	item_panel.queue_free()

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
	
	if panel == "items":
		active = $Powerups
		inactive = $General
		$Powerups/PowerupUpgrades.visible = true
	else:
		active = $General
		inactive = $Powerups
		$Powerups/PowerupUpgrades.visible = false
	
	
	active.z_index = 1
	active.mouse_filter = MOUSE_FILTER_STOP
	inactive.z_index = 0
	inactive.mouse_filter = MOUSE_FILTER_IGNORE
