extends Node2D

@export var panels: Dictionary[Node, LaunchPanel]

func _ready() -> void:
	GameManager.state_changed.connect(func (s):
		if s == Enums.State.LAUNCH:
			$Boost._set_progress(0))
	
	GameManager.planet_changed.connect(func (p):
		for n in panels.keys():
			n.visible = p in panels[n].planets
			)

func _on_launch_pressed() -> void:
	if pow($Boost/BoostDisplay.progress * 100, 1.4) * (1 - StatManager.get_stat("boost_discount").value / 10000) > GameManager.player.get_mineral(Enums.Mineral.CORUNDUM):
		return
		
	var cost := pow($Boost/BoostDisplay.progress * 100, 1.4)
	GameManager.state_changed.emit(Enums.State.MISSION)
	GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, -1 * cost)
	GameManager.boost.emit($Boost/BoostDisplay.progress)
	GameManager.clear_inventory.emit()

func _on_boost_display_progress_changed(progress: float) -> void:
	$Launch.disabled = GameManager.player.get_mineral(Enums.Mineral.CORUNDUM) < \
		floor(pow(progress * 100, 1.4) * (1 - StatManager.get_stat("boost_discount").value / 10000))
