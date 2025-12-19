extends Node2D

func _ready() -> void:
	$BarPanel/Bars/Red.pressed.connect(func (): update_stats("red"))
	$BarPanel/Bars/Orange.pressed.connect(func (): update_stats("orange"))
	$BarPanel/Bars/Green.pressed.connect(func (): update_stats("green"))
	$BarPanel/Bars/Blue.pressed.connect(func (): update_stats("blue"))
	
	GameManager.state_changed.connect(func (s): if s == Enums.State.SCIENTIST: update_bars())
	$Portion/Button.pressed.connect(update_bars)
	$BarPanel/Bars/NewPortion.new_bar_unlocked.connect(func (c): update_stats(c); update_bars())
	
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
		if button.has_meta("bar"): button._set_portion()
	
	$BarPanel/Bars/NewPortion.visible = GameManager.get_stat("blue_portion").level == 1
