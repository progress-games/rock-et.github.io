extends Node2D

var scenes = {
	"asteroids": preload("res://mission/manager/asteroid_manager.tscn")
}

## An array of which asteroids can spawn when and their associated data
@export var asteroids: Array[AsteroidData]

## A dictionary with any weight multipliers 
var weights: Dictionary[GameManager.Asteroid, float]

func _ready() -> void:
	var new_asteroids = scenes.get("asteroids").instantiate()
	new_asteroids.asteroids = asteroids
	new_asteroids.weights = weights
	add_child(new_asteroids)
