extends Control

const TAB_HEIGHT := 5
const TAB_BOUNCE_DUR := 0.2
const BASE_PANEL_SIZE := 33
const DEFAULT_POWERUP := Powerup.PowerupType.SPEED_BOOST

var tabs: Dictionary[Powerup.PowerupType, TextureButton]
var tab_tweens: Dictionary[Powerup.PowerupType, Tween]

@onready var tabs_hbox: HBoxContainer = $UpgradePanel/Tabs
@onready var upgrade_panel: NinePatchRect = $UpgradePanel
@onready var separator: ColorRect = $UpgradePanel/Separator

@onready var upgrade_button: UpgradeButton = $UpgradePanel/UpgradeButton
@onready var stat_display: StatDisplay = $UpgradePanel/StatDisplay
@onready var description: Label = $UpgradePanel/Description

func _ready() -> void:
	description.resized.connect(func ():
		upgrade_panel.size.y = BASE_PANEL_SIZE + (description.size.y if description.text != "" else 0.))
	setup_tabs()
	select_powerup(DEFAULT_POWERUP)

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
	description.text = stat.tooltip.replace("VALUE", str(int(ceil(stat.value))))
	description.add_theme_color_override("font_color", GameManager.powerup_data[p].colours.dark)

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
