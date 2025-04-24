extends Node2D

var scenes = {
	"asteroids": preload("res://scenes/mission/manager/asteroids.tscn")
}

func _ready() -> void:
	add_child(scenes.get("asteroids").instantiate())
