extends Node2D

const CLICK_BOX = preload("uid://by200eutp0c4c")
const INDENT := 30

var clicks: int = 0

const SIZE = Vector2(320, 180)

func clicked() -> void:
	clicks += 1
	
	for click_mode in ClickEffectManager.stats.keys():
		var stat = ClickEffectManager.stats[click_mode]
		for i in stat[ClickEffectManager.StatType.EVERY]:
			if clicks % i == 0:
				spawn_click_effect(click_mode)

func spawn_click_effect(effect: ClickEffectManager.ClickType) -> Node2D:
	var box = CLICK_BOX.instantiate()
	box.click_effect = effect
	box.global_position = random_pos()
	add_child(box)
	return box

func random_pos() -> Vector2:
	return Vector2(
		randi_range(int(-SIZE.x / 2 + INDENT), int(SIZE.x / 2 - INDENT)),
		randi_range(int(-SIZE.y / 2 + INDENT), int(SIZE.y / 2- INDENT))
	)
