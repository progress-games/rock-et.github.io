extends Control

const TAB_HEIGHT := 5
const TAB_BOUNCE_DUR := 0.2
const BASE_PANEL_SIZE := 33
const PANEL_ITEM_GAP := 4
const DEFAULT_POWERUP := Powerup.PowerupType.DOUBLE_MINERALS

var tabs: Dictionary[Powerup.PowerupType, TextureButton]
var tab_tweens: Dictionary[Powerup.PowerupType, Tween]
var scale_tween_ig: Tween

@onready var tabs_hbox: HBoxContainer = $UpgradePanel/Tabs
@onready var upgrade_panel: NinePatchRect = $UpgradePanel
@onready var separator: ColorRect = $UpgradePanel/Separator

@onready var upgrade_button: UpgradeButton = $UpgradePanel/UpgradeButton
@onready var stat_display: StatDisplay = $UpgradePanel/StatDisplay
@onready var description: Label = $UpgradePanel/Description

@onready var new_powerup: TextureButton = $New/NewPowerup
@onready var price: Label = $New/Price/Price
@onready var new: Control = $New

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.TUGTUPITE, 100000)
	
	description.resized.connect(func ():
		upgrade_panel.size.y = BASE_PANEL_SIZE + (description.size.y if description.text != "" else 0.))
	setup_tabs()
	select_powerup(DEFAULT_POWERUP)
	StatManager.get_stat("unlocked_powerups").upgraded.connect(func ():
		select_powerup(StatManager.get_stat("unlocked_powerups").level - 1)
		update_tab_vis()
		update_new_price()
	)
	
	new_powerup.mouse_entered.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
		new_powerup.material.set_shader_parameter("width", 1)
	)
	
	new_powerup.mouse_exited.connect(func ():
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
		new_powerup.material.set_shader_parameter("width", 0)
	)
	
	new_powerup.pressed.connect(
		func ():
			if StatManager.can_upgrade_stat("unlocked_powerups"):
				GameManager.add_mineral.emit(Enums.Mineral.TUGTUPITE, -StatManager.get_stat("unlocked_powerups").cost)
				StatManager.upgrade_stat("unlocked_powerups")
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
				pop()
			else:
				AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ERROR)
	)
	
	update_new_price()

func update_new_price(_s="") -> void:
	var s = StatManager.get_stat("unlocked_powerups")
	price.text = s.display_cost
	new.visible = s.max_level != s.level

func setup_tabs() -> void:
	for i in StatManager.powerup_order.size():
		var p = StatManager.powerup_order[i]
		tabs[i] = tabs_hbox.get_child(i)
		
		var tab = tabs[i]
		tab.set_meta("powerup", p)
		tab.material = tab.material.duplicate()
		tab.material.set_shader_parameter("replacement_colors", [
			GameManager.powerup_data[p].colours.dark,
			GameManager.powerup_data[p].colours.mid,
			GameManager.powerup_data[p].colours.light
		])
		tab.mouse_entered.connect(func (): on_tab_hover(i))
		tab.mouse_exited.connect(func (): off_tab_hover(i))
		tab.pressed.connect(func (): select_powerup(i))
		(tab.get_child(0) as TextureRect).texture = GameManager.powerup_data[p].texture

func update_tab_vis() -> void:
	var unlocked = StatManager.get_stat("unlocked_powerups")
	for i in range(tabs.size()):
		tabs[i].visible = unlocked.level - 1 >= i

func select_powerup(idx: int) -> void:
	var p = tabs[idx].get_meta('powerup')
	pop()
	upgrade_panel.material.set_shader_parameter("replacement_colors", [
			GameManager.powerup_data[p].colours.dark,
			GameManager.powerup_data[p].colours.mid,
			GameManager.powerup_data[p].colours.light
	])
	separator.material.set_shader_parameter("break_point", idx)
	
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

func pop() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.POP)
	if scale_tween_ig: scale_tween_ig.kill()
	scale_tween_ig = create_tween()
	scale_tween_ig.tween_property(self, "scale", Vector2.ONE * 1.15, 0.08)
	scale_tween_ig.tween_property(self, "scale", Vector2.ONE * 0.9, 0.05)
	scale_tween_ig.tween_property(self, "scale", Vector2.ONE, 0.02)

func on_tab_hover(idx: int) -> void:
	var tab = tabs[idx]
	
	if tab_tweens.has(idx): tab_tweens[idx].kill()
	tab_tweens[idx] = create_tween()
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	tab_tweens[idx].tween_property(tab, "position:y", -TAB_HEIGHT, TAB_BOUNCE_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func off_tab_hover(idx: int) -> void:
	var tab = tabs[idx]
	
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	if tab_tweens.has(idx): tab_tweens[idx].kill()
	tab_tweens[idx] = create_tween()
	tab_tweens[idx].tween_property(tab, "position:y", 0, TAB_BOUNCE_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
