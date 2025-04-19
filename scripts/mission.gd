extends Node2D

var scenes = {
	"asteroids": preload("res://scenes/asteroids.tscn")
}

func _ready() -> void:
	add_child(scenes.get("asteroids").instantiate())
