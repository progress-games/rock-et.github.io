extends Control

const STATS := [
	"powerup_duration",
	"powerup_spawn_rate",
	"powerup_ultra_chance"
]

@onready var item_upgrades := $Powerups/PowerupUpgrades/ItemUpgrades
@onready var item_panel := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel
@onready var item_stat := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel/StatDisplay
@onready var item_button := $Powerups/PowerupUpgrades/ItemUpgrades/DemoPanel/UpgradeButton

@onready var general_button := $General/GeneralUpgrades/HBoxContainer/UpgradeButton
@onready var general_display := $General/GeneralUpgrades/HBoxContainer/StatDisplay
@onready var general_upgrades := $General/GeneralUpgrades

@export var replacement_colours: Array[Color]

var current_panel := "general"

func _ready() -> void:
	_setup_items()
	_setup_general()
	
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha($Powerups.texture_normal.get_image(), 0.5)
	$Powerups.texture_click_mask = bitmap
	
	var gen_bitmap := BitMap.new()
	gen_bitmap.create_from_image_alpha($General.texture_normal.get_image(), 0.5)
	$General.texture_click_mask = gen_bitmap
	
	change_focus(current_panel)

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
		upgrade_button.material.set_shader_parameter("width", 0)
		
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
		var stat = GameManager.get_stat(stat_name)
		
		var button = general_button.duplicate()
		button.stat_name = stat.name
		button.material = button.material.duplicate()
		
		var stat_display = general_display.duplicate()
		stat_display.upgrade_button = button
		stat_display.texture = load("res://shikoba/assets/general/" + stat.name + ".png")
		
		var new_hbox = HBoxContainer.new()
		new_hbox.add_child(stat_display)
		new_hbox.add_child(button)
		general_upgrades.add_child(new_hbox)
	
	$General/GeneralUpgrades/HBoxContainer.queue_free()

func on_hover(panel: String) -> void:
	if panel == current_panel: return
	match panel:
		"items":
			$Powerups.material.set_shader_parameter("width", 1)
		"general":
			$General.material.set_shader_parameter("width", 1)

func off_hover(panel: String) -> void:
	if panel == current_panel: return
	match panel:
		"items":
			$Powerups.material.set_shader_parameter("width", 0)
		"general":
			$General.material.set_shader_parameter("width", 0)

func change_focus(panel: String) -> void:
	if panel == current_panel: return
	
	off_hover(panel)
	current_panel = panel
	print(current_panel)
	var p = $Powerups if panel == "items" else $General
	var _p = $Powerups if panel == "general" else $General
	
	p.z_index += 1
	_p.z_index -= 1
	
