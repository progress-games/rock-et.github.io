extends Object 
class_name SaveFile

var minerals: Dictionary[Enums.Mineral, int]
var stats: Dictionary[String, Stat]
var items: Dictionary[String, Item]
var day: int
var states: Dictionary[Enums.State, Dictionary]
"""
for each state:
	if its revealed or not
	dialogue progression
also:
	exchange rate
	
"""

func capture_state() -> void:
	minerals = GameManager.player.minerals.duplicate()
	stats = GameManager.player.stats.duplicate(true)
	items = GameManager.player.owned_items.duplicate(true)
	day = GameManager.day
