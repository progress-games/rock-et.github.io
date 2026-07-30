extends TextureRect

var next_merchant_date: int = -1

@onready var day_1: Label = $Day1

func _ready() -> void:
	visible = false
	GameManager.day_changed.connect(update_day)
	StatManager.get_stat("stall_level").upgraded.connect(
		func ():
			if StatManager.get_stat("stall_level").level == 4: next_merchant_date -= 2
	)

func update_day(day: int) -> void:
	if !GameManager.player.has_discovered_state(Enums.State.MERCHANT): 
		next_merchant_date = day + 4
		return
	
	if next_merchant_date == day:
		visible = false
		next_merchant_date = day + (4 if StatManager.get_stat("stall_level").level < 4 else 2)
		return
	
	visible = true
	day_1.text = str(next_merchant_date)
