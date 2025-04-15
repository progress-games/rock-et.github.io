extends Node2D

@onready var upgrade_container: HFlowContainer = $Upgrades
var scenes := {
	"upgrade_button": preload("res://scenes/upgrade_button.tscn")
}

func _ready() -> void:
	var stats = GameManager.player.get_stats()
	
	for _name in stats:
		var button = scenes.get("upgrade_button").instantiate() as UpgradeButton
		button.set_stat(stats.get(_name))
		upgrade_container.add_child(button)
