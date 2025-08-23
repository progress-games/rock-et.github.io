extends Node2D

func _on_ship_value_changed(value: float) -> void:
	$Launch.disabled = GameManager.player.get_mineral(Enums.Mineral.CORUNDUM) < \
		pow($Boost/Ship.value * 100, 1.4)


func _on_launch_pressed() -> void:
	var cost := pow($Boost/Ship.value * 100, 1.4)
	GameManager.state_changed.emit(Enums.State.MISSION)
	GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, -1 * cost)
	GameManager.boost.emit($Boost/Ship.value)
