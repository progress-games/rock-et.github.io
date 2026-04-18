extends Node2D

@onready var bars: Dictionary[String, HitBarUpgradeUI] = {
	"red": $BarPanel/Bars/Red,
	"orange": $BarPanel/Bars/Orange,
	"green": $BarPanel/Bars/Green,
	"blue": $BarPanel/Bars/Blue
}

@onready var buttons: Dictionary[String, UpgradeButton] = {
	"damage": $Damage/Button,
	"portion": $Portion/Button,
	"yield": $Yield/Button
}
@onready var new_portion: TextureButton = $BarPanel/Bars/NewPortion

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
	
	selected_stat(selected_colour)

func selected_stat(colour: String) -> void:
	selected_colour = colour
	for button_type in buttons.keys():
		buttons[button_type].change_stat(colour + "_" + button_type)
	
	for bar in bars.values():
		bar._was_selected(colour)

func updated_stat() -> void:
	new_portion.visible = StatManager.get_stat("blue_portion").level == 1
	bars.values().map(func (x): x._set_portion())
	selected_stat(selected_colour)
