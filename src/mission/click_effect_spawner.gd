extends Node2D

const CLICK_BOX = preload("uid://by200eutp0c4c")
const INDENT := 30

var clicks: int = 0

## i dont give a shit
@onready var boundary: Area2D = $"../Boundary"

func clicked() -> void:
	clicks += 1
	
	for click_mode in ClickEffectManager.stats.keys():
		var stat = ClickEffectManager.stats[click_mode]
		for i in stat[ClickEffectManager.StatType.EVERY]:
			if clicks % i == 0:
				var box = CLICK_BOX.instantiate()
				box.click_effect = click_mode
				box.global_position = random_pos()
				add_child(box)

func random_pos() -> Vector2:
	var size = boundary.get_node("CollisionShape2D").shape.extents
	
	return Vector2(
		randi_range(int(boundary.global_position.x - size.x * 2 + INDENT), int(boundary.global_position.x - INDENT)),
		randi_range(int(boundary.global_position.y - size.y * 2 + INDENT), int(boundary.global_position.y - INDENT))
	)
