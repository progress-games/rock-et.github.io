extends Control

func _ready() -> void:
	$Intended.mouse_entered.connect(func (): $Intended.material.set_shader_parameter("width", 1))
	$Intended.mouse_exited.connect(func (): $Intended.material.set_shader_parameter("width", 0))
	$Intended.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: queue_free())
	
	$LittleLess.mouse_entered.connect(func (): $LittleLess.material.set_shader_parameter("width", 1))
	$LittleLess.mouse_exited.connect(func (): $LittleLess.material.set_shader_parameter("width", 0))
	$LittleLess.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: 
		GameManager.click_multiplier = 1.5
		queue_free())
	
	$LotLess.mouse_entered.connect(func (): $LotLess.material.set_shader_parameter("width", 1))
	$LotLess.mouse_exited.connect(func (): $LotLess.material.set_shader_parameter("width", 0))
	$LotLess.gui_input.connect(func(event): if event is InputEventMouseButton and event.pressed: 
		GameManager.click_multiplier = 2.
		queue_free())
	
