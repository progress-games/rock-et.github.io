extends Control

const OUTLINE_COLOUR := Color(0.18, 0.133, 0.184, 1.0)
const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const CANS := [
	preload("uid://b16xwu5q1ciq6"),
	preload("uid://cpj7wxhe60htk"),
	preload("uid://bwmilfdkmg5jy"),
	preload("uid://1bi3y7vqekod"),
	preload("uid://0si2vjuc320o"),
	preload("uid://bt8tcnwl77p6s"),
	preload("uid://d1xtw3bbpqjyv")
]

const SHELF_COLUMNS = 7
const SHELF_ROWS = 4

@onready var grid_container: GridContainer = $GridContainer

func _ready() -> void:
	generate_cans(TempestManager.TempestType.SNOW_TRAIL)

func generate_cans(tempest: TempestManager.TempestType) -> void:
	grid_container.get_children().map(func (x): x.queue_free())
	
	var outline = ShaderMaterial.new()
	outline.shader = WHITE_OUTLINE
	
	var rng = RandomNumberGenerator.new()
	rng.seed = tempest
	
	for i in range(SHELF_COLUMNS * SHELF_ROWS):
		var new_can = TextureButton.new()
		new_can.texture_normal = CANS[rng.randi_range(0, CANS.size() - 1)]
		grid_container.add_child(new_can)
		
		new_can.material = outline.duplicate()
		new_can.material.set_shader_parameter("color", OUTLINE_COLOUR)
		new_can.mouse_entered.connect(func (): new_can.material.set_shader_parameter("color", Color.WHITE))
		new_can.mouse_exited.connect(func (): new_can.material.set_shader_parameter("color", OUTLINE_COLOUR))
		
