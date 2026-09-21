extends Node2D

const CLICK_BOX = preload("uid://by200eutp0c4c")
const INDENT := 30

var clicks: int = 0

const SIZE = Vector2(320, 180)

signal click_effect_spawned()

func clicked() -> void:
	clicks += 1
	
	for click_mode in ClickEffectManager.stats.keys():
		var stat = ClickEffectManager.stats[click_mode]
		for i in stat[ClickEffectManager.StatType.EVERY]:
			if clicks % i == 0:
				spawn_click_effect(click_mode)
				click_effect_spawned.emit()

func spawn_click_effect(
		effect: ClickEffectManager.ClickType, 
		position_override: Vector2 = Vector2.ZERO,
		damage_override: float = -1.,
		size_override: float = -1.) -> Node2D:
	var box = CLICK_BOX.instantiate()
	box.click_effect = effect
	
	if position_override == Vector2.ZERO:
		if GameManager.lock_on_positions.size() > 0:
			box.global_position = GameManager.lock_on_positions.pop_front()
		else:
			box.global_position = random_pos()
	else:
		box.global_position = position_override
	
	box.lighten_borders = get_parent().progress > 0.45
	if damage_override != -1.:
		box.damage_override = damage_override
		box.size_override = size_override
	add_child(box)
	
	return box

func random_pos() -> Vector2:
	return Vector2(
		randi_range(int(-SIZE.x / 2 + INDENT), int(SIZE.x / 2 - INDENT)),
		randi_range(int(-SIZE.y / 2 + INDENT), int(SIZE.y / 2- INDENT))
	)
