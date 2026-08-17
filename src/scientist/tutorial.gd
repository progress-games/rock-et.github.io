extends Control

@onready var text: Control = $Text

var full_dialogues: Array[String]

var current_idx: int = 0

@onready var bg: ColorRect = $BG2

@onready var orange: HitBarUpgradeUI = $"../BarUpgrades/BarPanel/Bars/Orange"
@onready var power_level: UpgradeButton = $"../BarUpgrades/Power/Button"
@onready var power_upgrades: Control = $"../BarUpgrades/PowerUpgrades"
@onready var red: HitBarUpgradeUI = $"../BarUpgrades/BarPanel/Bars/Red"
@onready var fake_button: Button = $FakeButton
@onready var bars: HBoxContainer = $"../BarUpgrades/BarPanel/Bars"

@onready var next: Button = $Next

func _ready() -> void:
	hide()
	next.hide()
	
	next.pressed.connect(func (): 
		var n = current_idx + 1
		if n == full_dialogues.size():
			GameManager.tutorial_progress.append(Enums.Tutorial.SCIENTIST_BARS)
			queue_free()
		else:
			next_line(n)
			next.hide())
	
	for l in text.get_children():
		full_dialogues.append(l.text)
		l.text = ""
		l.hide()
	
	
	StatManager.get_stat("orange_portion").upgraded.connect(
		func (): show(); next_line(current_idx)
	)
	#$"../First".tree_exited.connect(func (): show(); next_line(current_idx))

func hovering_power_level() -> void:
	power_upgrades.z_index = 6

func off_hover_power_level() -> void:
	power_upgrades.z_index = 0

func z_front() -> int:
	return bg.z_index + z_index + 1

func next_line(idx: int) -> void:
	if idx > 0:
		text.get_child(idx - 1).hide()
	
	current_idx = idx
	var label = text.get_child(current_idx)
	label.show()
	
	var t = create_tween()
	t.tween_property(label, "text", full_dialogues[current_idx], 0.03 * full_dialogues[current_idx].length())
	
	match idx:
		0:
			# put orange at front
			#orange.show()
			orange.z_index = z_front()
			
			# put fake button at orange position
			fake_button.global_position = bars.global_position + \
				Vector2(bars.size.x * (red.size_flags_stretch_ratio / 100) - orange.size.x, 0)
			fake_button.size = Vector2(bars.size.x * (orange.size_flags_stretch_ratio / 100), \
				bars.size.y)
			
			# connect fake button to orange
			fake_button.pressed.connect(func (): orange.pressed.emit(); next_line(idx + 1), CONNECT_ONE_SHOT)
			fake_button.mouse_entered.connect(orange.mouse_entered.emit)
			fake_button.mouse_exited.connect(orange.mouse_exited.emit)
		1:
			# put power level at front
			orange.z_index = 0
			power_level.z_index = z_front()
			
			# put fake button at power level position
			fake_button.global_position = power_level.global_position
			fake_button.size = power_level.size
			
			# disconnect fake button from orange
			fake_button.mouse_entered.disconnect(orange.mouse_entered.emit)
			fake_button.mouse_exited.disconnect(orange.mouse_exited.emit)
			
			# connect fake button to power level and z index functions
			fake_button.mouse_entered.connect(func (): next_line(idx + 1), CONNECT_ONE_SHOT)
			fake_button.mouse_entered.connect(power_level.mouse_entered.emit)
			fake_button.mouse_exited.connect(power_level.mouse_exited.emit)
			fake_button.mouse_entered.connect(hovering_power_level)
			fake_button.mouse_exited.connect(off_hover_power_level)
		2:
			# player can read stats. once text is finished, player can click next
			t.finished.connect(func (): next.show())
		3: 
			# put red at front
			power_upgrades.z_index = 0
			power_level.z_index = 0
			red.z_index = z_front()
			
			# move fake button to red bar
			fake_button.global_position = bars.global_position
			fake_button.size = Vector2(bars.size.x * (red.size_flags_stretch_ratio / 100),\
				bars.size.y)
			
			# disconnect fake button from power button
			fake_button.mouse_entered.disconnect(power_level.mouse_entered.emit)
			fake_button.mouse_exited.disconnect(power_level.mouse_exited.emit)
			fake_button.mouse_entered.disconnect(hovering_power_level)
			fake_button.mouse_exited.disconnect(off_hover_power_level)
			
			# connect fake button to red portion
			fake_button.pressed.connect(func (): red.pressed.emit(); next_line(idx + 1), CONNECT_ONE_SHOT)
			fake_button.mouse_entered.connect(red.mouse_entered.emit)
			fake_button.mouse_exited.connect(red.mouse_exited.emit)
		4:
			# put power level at top
			red.z_index = 0
			power_level.z_index = z_front()
			
			# put fake button at power level
			fake_button.global_position = power_level.global_position
			fake_button.size = power_level.size
			
			# disconnect fake button from red portion
			fake_button.mouse_entered.disconnect(red.mouse_entered.emit)
			fake_button.mouse_exited.disconnect(red.mouse_exited.emit)
			
			# connect fake button to power level
			fake_button.mouse_entered.connect(func (): next_line(idx + 1), CONNECT_ONE_SHOT)
			fake_button.mouse_entered.connect(power_level.mouse_entered.emit)
			fake_button.mouse_exited.connect(power_level.mouse_exited.emit)
			fake_button.mouse_entered.connect(hovering_power_level)
			fake_button.mouse_exited.connect(off_hover_power_level)
		5:
			# read text and can click next
			t.finished.connect(func (): next.show())
		6:
			# hide everything
			fake_button.queue_free()
			power_upgrades.z_index = 0
			power_level.z_index = 0
			
			# read text
			t.finished.connect(func (): next.show())
		7:
			# last
			t.finished.connect(func (): next.show())
		8:
			t.finished.connect(func (): next.show())
			next.text = "done!"
			
			
