extends Control

const BASE_SHIP_POS = Vector2(-5, 85)
const HEIGHT = 79
@onready var ship: TextureRect = $Ship

@onready var middle: ColorRect = $Bar/Middle
@onready var left: ColorRect = $Bar/Left
@onready var right: ColorRect = $Bar/Right
@onready var next: TextureRect = $Next
const PLANET = preload("uid://dafx8djy3janm")

var next_mineral: int = 0

var all_minerals: Array[Enums.Mineral]
var mineral_progress: Array[float]
var target_progress: float

func _ready() -> void:
	if StatManager.get_stat("thruster_speed").level == 1:
		hide()
	
	var spawns = GameManager.asteroid_spawns.filter(
		func (d):
			return GameManager.planet in d.planets
	)
	
	spawns.sort_custom(
		func (a, b):
			return a.start < b.start
	)
	
	for m in spawns:
		all_minerals.append(m.drops[0])
		mineral_progress.append(m.start)
	
	update_mineral()

func update_progress(p: float) -> void:
	left.material.set_shader_parameter("progress", p)
	middle.material.set_shader_parameter("progress", p)
	right.material.set_shader_parameter("progress", p)
	
	ship.position = BASE_SHIP_POS - Vector2(0, p * HEIGHT)

func update_mineral() -> void:
	next_mineral += 1
	
	if next_mineral < all_minerals.size():
		target_progress = mineral_progress[next_mineral] - mineral_progress[next_mineral - 1]
		next.texture = GameManager.mineral_data[all_minerals[next_mineral]].texture
	else:
		target_progress = 1.
		next.self_modulate = Color.TRANSPARENT

func update_distance(d: float) -> void:
	var current_progress = (d / GameManager.planet_distance) - mineral_progress[next_mineral - 1]
	
	update_progress(current_progress / target_progress)
	
	if current_progress >= target_progress:
		update_mineral()
