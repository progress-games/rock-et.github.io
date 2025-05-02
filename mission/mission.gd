extends Node2D

var scenes = {
	"asteroids": preload("res://mission/manager/asteroid_manager.tscn")
}

func _ready() -> void:
	add_child(scenes.get("asteroids").instantiate())
