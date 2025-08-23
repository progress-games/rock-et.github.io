extends Node2D

func _ready() -> void:
	$BarPanel/Bars/Red.pressed.connect(func (): update_stats("red"))
	$BarPanel/Bars/Orange.pressed.connect(func (): update_stats("orange"))
	$BarPanel/Bars/Green.pressed.connect(func (): update_stats("green"))
	$BarPanel/Bars/Blue.pressed.connect(func (): update_stats("blue"))
	
	$Portion/Button.pressed.connect(update_bars)
	
	update_stats('red')
	

func update_stats(colour: String) -> void:
	$Damage/Button.change_stat(colour + "_damage")
	$Portion/Button.change_stat(colour + "_portion")
	$Yield/Button.change_stat(colour + "_yield")
	
	$BarPanel/Bars/Red._was_selected(colour)
	$BarPanel/Bars/Orange._was_selected(colour)
	$BarPanel/Bars/Green._was_selected(colour)
	$BarPanel/Bars/Blue._was_selected(colour)
	

func update_bars() -> void:
	for button in $BarPanel/Bars.get_children():
		button._set_portion()
