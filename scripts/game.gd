extends Node2D

@onready var upgrade_container: HFlowContainer = $UI/Upgrades
var scenes := {
	"upgrade_button": preload("res://scenes/upgrade_button.tscn"),
	"mission": preload("res://scenes/mission.tscn")
}

func _ready() -> void:
	var stats = GameManager.player.get_stats()
	
	for _name in stats:
		var button = scenes.get("upgrade_button").instantiate() as UpgradeButton
		button.set_stat(stats.get(_name))
		upgrade_container.add_child(button)
	
	GameManager.state_changed.connect(_state_changed)

func _state_changed(new_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.MISSION:
			add_child(scenes.get("mission").instantiate())

func _on_embark_pressed() -> void:
	GameManager.state_changed.emit(GameManager.State.MISSION)
