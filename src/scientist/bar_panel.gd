extends Node2D

@onready var bars: Dictionary[String, HitBarUpgradeUI] = {
	"red": $BarPanel/Bars/Red,
	"orange": $BarPanel/Bars/Orange,
	"green": $BarPanel/Bars/Green,
	"blue": $BarPanel/Bars/Blue
}

@onready var buttons: Dictionary[String, UpgradeButton] = {
	"power": $Power/Button,
	"portion": $Portion/Button,
	"yield": $Yield/Button
}
@onready var new_portion: TextureButton = $BarPanel/Bars/NewPortion
@onready var locked_portion: TextureRect = $Portion/LockedPortion

@onready var current: Control = $PowerUpgrades/Current
@onready var current_level: RichTextLabel = $PowerUpgrades/Current/Level/MarginContainer/RichTextLabel
@onready var current_desc: RichTextLabel = $PowerUpgrades/Current/Description/MarginContainer/RichTextLabel

@onready var next_arrows: Control = $PowerUpgrades/NextArrows

@onready var next: Control = $PowerUpgrades/Next
@onready var next_level: RichTextLabel = $PowerUpgrades/Next/Level/MarginContainer/RichTextLabel
@onready var next_desc: RichTextLabel = $PowerUpgrades/Next/Description/MarginContainer/RichTextLabel

var selected_colour := "red"

func _ready() -> void:
	for colour in bars.keys():
		bars[colour].pressed.connect(func (): selected_stat(colour))
		StatManager.get_stat(colour + "_portion").upgraded.connect(updated_stat)
		StatManager.get_stat(colour + "_portion").resetted.connect(updated_stat)
	
	new_portion.new_bar_unlocked.connect(func (c): 
		selected_stat(c);
		updated_stat()
	)
	
	StatManager.stat_upgraded.connect(func (s: Stat): 
		locked_portion.visible = locked_portion.visible && \
			s.stat_name != "blue_portion"
		if s.stat_name.find("_power") != -1: show_power_desc()
	)
	
	buttons.power.mouse_entered.connect(show_power_desc)
	buttons.power.mouse_exited.connect(hide_power_desc)
	
	hide_power_desc()
	
	selected_stat(selected_colour)
	#GameManager.add_mineral.emit(Enums.Mineral.OLIVINE, 10000)

func selected_stat(colour: String) -> void:
	selected_colour = colour
	for button_type in buttons.keys():
		buttons[button_type].change_stat(colour + "_" + button_type)
	
	for bar in bars.values():
		bar._was_selected(colour)

func updated_stat() -> void:
	new_portion.visible = StatManager.get_stat("blue_portion").level == 1 && new_portion.visible
	bars.values().map(func (x): x._set_portion())
	selected_stat(selected_colour)

func get_sprite_str(s: String) -> String:
	return "[img]res://scientist/assets/level up/" + s + ".png[/img] "

func show_power_desc() -> void:
	current_level.text = get_sprite_str("power_level") + \
		StatManager.get_stat(selected_colour + "_power").display_value
	
	current_desc.text = get_sprite_str("damage") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "damage"), 0.01)) +\
		"x " + get_sprite_str("mineral") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "mineral"), 0.01)) +\
		"x " + get_sprite_str("size") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "size"), 0.01)) + "x"
	
	next_level.text = get_sprite_str("power_level") + \
		StatManager.get_stat(selected_colour + "_power").next_level.display_value
	
	next_desc.text = get_sprite_str("damage") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "damage", true), 0.01)) +\
		"x " + get_sprite_str("mineral") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "mineral", true), 0.01)) +\
		"x " + get_sprite_str("size") + \
		str(snappedf(StatManager.get_portion_power(selected_colour, "size", true), 0.01)) + "x"
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(current, "position:y", -4, 0.2)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(next_arrows, "position:y", 0, 0.22)
	
	var t3 = create_tween()
	t3.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t3.tween_property(next, "position:y", 33, 0.25)

func hide_power_desc() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(current, "position:y", -40, 0.21)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t2.tween_property(next_arrows, "position:y", -50, 0.23)
	
	var t3 = create_tween()
	t3.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t3.tween_property(next, "position:y", -40, 0.26)
