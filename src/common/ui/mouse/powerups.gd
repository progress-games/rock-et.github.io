extends HBoxContainer

# includes super powerups too
# eg. "falseSPEED_BOOST" is not super, speed boost
var powerups: Dictionary[String, TextureRect]
var powerup_timers: Array[Timer]

func _ready() -> void:
	setup_powerups()
	GameManager.powerup_hit.connect(func (p): increment_count(p.super_powerup, p.powerup_type))
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.MISSION: 
			powerup_timers.map(func (t): t.timeout.emit()))

func setup_powerups() -> void:
	for powerup in GameManager.powerup_data.keys():
		# not super
		var rect = $SpeedBoost.duplicate() as TextureRect
		rect.texture = GameManager.powerup_data[powerup].small
		rect.get_child(0).text = "x0"
		rect.visible = false
		add_child(rect)
		powerups[str(false) + str(powerup)] = rect
	
		# super
		var rect_s = $SpeedBoostSuper.duplicate() as TextureRect
		rect_s.texture = GameManager.powerup_data[powerup].small
		rect_s.get_child(0).text = "x0"
		rect_s.visible = false
		add_child(rect_s)
		powerups[str(true) + str(powerup)] = rect_s
	
	$SpeedBoost.queue_free()
	$SpeedBoostSuper.queue_free()

func increment_count(super_powerup: bool, powerup: Powerup.PowerupType, amount: int = 1) -> void:
	var p_name = str(super_powerup) + str(powerup)
	
	var label = powerups[p_name].get_child(0) as Label
	var curr = int(label.text.replace("x", "")) + amount
	
	powerups[p_name].visible = curr > 0
	label.text = "x" + str(curr)
	
	if amount == 1:
		var t = Timer.new()
		t.wait_time = StatManager.get_stat("powerup_duration").value
		t.timeout.connect(func (): 
			increment_count(super_powerup, powerup, -1); 
			powerup_timers.erase(t); 
			t.queue_free())
		add_child(t)
		powerup_timers.append(t)
		t.start()
