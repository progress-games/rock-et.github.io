extends Sprite2D

func _ready() -> void:
	$Bars/Red.pressed.connect(func (): update_stats("red"))
	$Bars/Orange.pressed.connect(func (): update_stats("orange"))
	$Bars/Green.pressed.connect(func (): update_stats("green"))
	$Bars/Blue.pressed.connect(func (): update_stats("blue"))
	
	$Portion/Button.pressed.connect(update_bars)
	
	update_stats('red')
	

func update_stats(colour: String) -> void:
	$Damage/Button.change_stat(colour + "_damage")
	$Portion/Button.change_stat(colour + "_portion")
	$Yield/Button.change_stat(colour + "_yield")
	
	$Bars/Red._was_selected(colour)
	$Bars/Orange._was_selected(colour)
	$Bars/Green._was_selected(colour)
	$Bars/Blue._was_selected(colour)
	

func update_bars() -> void:
	for button in $Bars.get_children():
		button._set_portion()
