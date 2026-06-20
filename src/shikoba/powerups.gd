extends Control

@export var new_powerup_colours: Dictionary[String, Color] = {
	"dark": Color(),
	"mid": Color(),
	"light": Color()
}

const NEW_POWERUP_TEX := preload("uid://cxqstt0h531fg")
const TAB_HEIGHT := 5
const TAB_BOUNCE_DUR := 0.2
const BASE_PANEL_SIZE := 33
const PANEL_ITEM_GAP := 4
const DEFAULT_POWERUP := Powerup.PowerupType.SPEED_BOOST

var tabs: Dictionary[Powerup.PowerupType, TextureButton]
var tab_tweens: Dictionary[Powerup.PowerupType, Tween]

@onready var tabs_hbox: HBoxContainer = $UpgradePanel/Tabs
@onready var upgrade_panel: NinePatchRect = $UpgradePanel
@onready var separator: ColorRect = $UpgradePanel/Separator
@onready var new_powerup_tab: TextureButton = $UpgradePanel/Tabs/TextureButton9

@onready var upgrade_button: UpgradeButton = $UpgradePanel/UpgradeButton
@onready var stat_display: StatDisplay = $UpgradePanel/StatDisplay
@onready var description: Label = $UpgradePanel/Description

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.TUGTUPITE, 100000)
	
	description.resized.connect(func ():
		upgrade_panel.size.y = BASE_PANEL_SIZE + (description.size.y if description.text != "" else 0.))
	setup_tabs()
	select_powerup(DEFAULT_POWERUP)
	StatManager.get_stat("unlocked_powerups").upgraded.connect(func ():
		select_powerup(StatManager.get_stat("unlocked_powerups").level - 1)
		update_tab_vis()
		)

func setup_tabs() -> void:
	for p in Powerup.PowerupType.values():
		tabs[p] = tabs_hbox.get_child(p)
		
		var tab = tabs[p]
		tab.set_meta("powerup", p)
		tab.material = tab.material.duplicate()
		tab.material.set_shader_parameter("replacement_colors", [
			GameManager.powerup_data[p].colours.dark,
			GameManager.powerup_data[p].colours.mid,
			GameManager.powerup_data[p].colours.light
		])
		tab.mouse_entered.connect(func (): on_tab_hover(p))
		tab.mouse_exited.connect(func (): off_tab_hover(p))
		tab.pressed.connect(func (): select_powerup(p))
		(tab.get_child(0) as TextureRect).texture = GameManager.powerup_data[p].texture
	
	var p = Powerup.PowerupType.size()
	tabs[p] = new_powerup_tab
	new_powerup_tab.mouse_entered.connect(func (): on_tab_hover(p))
	new_powerup_tab.mouse_exited.connect(func (): off_tab_hover(p))
	new_powerup_tab.pressed.connect(select_new_powerup)

func update_tab_vis() -> void:
	var unlocked = StatManager.get_stat("unlocked_powerups")
	for i in range(tabs.size()):
		tabs[i].visible = unlocked.level - 1 >= i
	
	tabs[Powerup.PowerupType.size()].visible = unlocked.level != unlocked.max_level

func select_new_powerup() -> void:
	upgrade_panel.material.set_shader_parameter("replacement_colors", [
			new_powerup_colours.dark,
			new_powerup_colours.mid,
			new_powerup_colours.light
	])
	separator.material.set_shader_parameter("break_point", StatManager.get_stat("unlocked_powerups").level)
	
	upgrade_button.change_stat("unlocked_powerups")
	upgrade_button.material.set_shader_parameter("replacement_colors", [
			new_powerup_colours.dark,
			new_powerup_colours.mid,
			new_powerup_colours.light
	])
	
	stat_display.texture = NEW_POWERUP_TEX
	stat_display.font_colour = new_powerup_colours.dark
	stat_display.upgrade_colour = new_powerup_colours.light
	stat_display.refresh()
	
	var stat = StatManager.get_stat("unlocked_powerups")
	description.text = stat.tooltip.replace("VALUE", stat.update_display(false))
	description.add_theme_color_override("font_color", new_powerup_colours.dark)
	
	upgrade_panel.size.y = upgrade_button.size.y + 2 * PANEL_ITEM_GAP


func select_powerup(p: Powerup.PowerupType) -> void:
	upgrade_panel.material.set_shader_parameter("replacement_colors", [
			GameManager.powerup_data[p].colours.dark,
			GameManager.powerup_data[p].colours.mid,
			GameManager.powerup_data[p].colours.light
	])
	separator.material.set_shader_parameter("break_point", tabs.keys().find(p))
	
	var stat_name = Powerup.PowerupType.find_key(p).to_lower() + "_powerup"
	upgrade_button.change_stat(stat_name)
	upgrade_button.material.set_shader_parameter("replacement_colors", [
			GameManager.powerup_data[p].colours.dark,
			GameManager.powerup_data[p].colours.mid,
			GameManager.powerup_data[p].colours.light
	])
	
	stat_display.texture = GameManager.powerup_data[p].texture
	stat_display.font_colour = GameManager.powerup_data[p].colours.dark
	stat_display.upgrade_colour = GameManager.powerup_data[p].colours.light
	stat_display.refresh()
	
	var stat = StatManager.get_stat(stat_name)
	description.text = stat.tooltip.replace("VALUE", stat.update_display(false))
	description.add_theme_color_override("font_color", GameManager.powerup_data[p].colours.dark)
	
	upgrade_panel.size.y = upgrade_button.size.y + description.get_minimum_size().y + 2 * PANEL_ITEM_GAP

func on_tab_hover(powerup: Powerup.PowerupType) -> void:
	var tab = tabs[powerup]
	
	if tab_tweens.has(powerup):
		tab_tweens[powerup].kill()
	
	tab_tweens[powerup] = create_tween()
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	tab_tweens[powerup].tween_property(tab, "position:y", -TAB_HEIGHT, TAB_BOUNCE_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func off_tab_hover(powerup: Powerup.PowerupType) -> void:
	var tab = tabs[powerup]
	
	if tab_tweens.has(powerup): tab_tweens[powerup].kill()
	
	tab_tweens[powerup] = create_tween()
	tab_tweens[powerup].tween_property(tab, "position:y", 0, TAB_BOUNCE_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
