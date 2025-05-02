extends Node2D

@onready var main_camera: Camera2D = $MainCamera
var scenes := {
	"mission": preload("res://mission/mission.tscn")
}

func _ready() -> void:

	GameManager.state_changed.connect(_state_changed)

func _state_changed(new_state: GameManager.State) -> void:
	match new_state:
		GameManager.State.MISSION:
			main_camera.add_child(scenes.get("mission").instantiate())
