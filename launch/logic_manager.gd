extends Node2D

func _on_launch_pressed() -> void:
	if pow($Boost/BoostDisplay.progress * 100, 1.4) * (1 - GameManager.player.get_stat("boost_discount").value / 10000) > GameManager.player.get_mineral(Enums.Mineral.CORUNDUM):
		return
		
	var cost := pow($Boost/BoostDisplay.progress * 100, 1.4)
	GameManager.state_changed.emit(Enums.State.MISSION)
	GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, -1 * cost)
	GameManager.boost.emit($Boost/BoostDisplay.progress)
	GameManager.show_mineral.emit(Enums.Mineral.AMETHYST)


func _on_boost_display_progress_changed(progress: float) -> void:
	$Launch.disabled = GameManager.player.get_mineral(Enums.Mineral.CORUNDUM) < \
		pow(progress * 100, 1.4) * (1 - GameManager.player.get_stat("boost_discount").value / 10000)
