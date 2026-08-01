extends Control

const TEXT_COLOURS := {
	TempestManager.TempestType.SNOW_TRAIL: Color("625565"),
	TempestManager.TempestType.HAILSTORM: Color("4d9be6")
}

const PANEL_COLOURS := {
	TempestManager.TempestType.SNOW_TRAIL: Color("FFFFFF"),
	TempestManager.TempestType.HAILSTORM: Color("8fd3ff")
}

const TEMPEST_SPRITES := {
	TempestManager.TempestType.SNOW_TRAIL: preload("uid://di2tpn8x13yma"),
	TempestManager.TempestType.HAILSTORM: preload("uid://dhlxuxld5j8wm")
}

const TEMPEST_ARROWS := {
	TempestManager.TempestType.SNOW_TRAIL: preload("uid://3ohx46wjkdm7"),
	TempestManager.TempestType.HAILSTORM: preload("uid://dk20so3arbl6g"),
}

const ORIGINAL_COLOURS := [
	Color(0.902, 0.565, 0.306, 1.0),
	Color(0.804, 0.408, 0.239, 1.0),
	Color(0.62, 0.271, 0.224, 1.0)
]

const AMAZONITE_PATH := "[img]res://common/minerals/amazonite.png[/img] "
const OUTLINE_COLOUR := Color(0.18, 0.133, 0.184, 1.0)
const WHITE_OUTLINE = preload("uid://bdsus7hm4q1wt")
const CANS := [
	preload("uid://b16xwu5q1ciq6"),
	preload("uid://cpj7wxhe60htk"),
	preload("uid://bwmilfdkmg5jy"),
	preload("uid://1bi3y7vqekod"),
	preload("uid://0si2vjuc320o"),
	preload("uid://bt8tcnwl77p6s"),
	preload("uid://d1xtw3bbpqjyv"),
	preload("uid://brcmdopci2qw6"),
	preload("uid://0wfjnj813qm3")
]

const SHELF_COLUMNS = 7
const SHELF_ROWS = 4

@export var snow_trail_rows: Array[UpgradeRow]
@export var hailstorm_rows: Array[UpgradeRow]
@export var replacement_colours: Array[ColorTrio]

@onready var description: HBoxContainer = $Description

@onready var description_text: RichTextLabel = $Description/Description/MarginContainer2/RichTextLabel
@onready var description_panel: NinePatchRect = $Description/Description/NinePatchRect

@onready var price_text: RichTextLabel = $Description/Price/MarginContainer2/RichTextLabel
@onready var price_panel: NinePatchRect = $Description/Price/NinePatchRect

@onready var grid_container: GridContainer = $Shelves/GridContainer
@onready var shelves: TextureRect = $Shelves

@onready var swap: TextureButton = $Swap
@onready var selected_tempest_texture: TextureRect = $SelectedPanel/Selected/SelectedTempest
@onready var selected_tempest_label: Label = $SelectedPanel/Selected/Label
@onready var selected_panel: NinePatchRect = $SelectedPanel

func _ready() -> void:
	swap.mouse_entered.connect(func (): 
		swap.material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	swap.mouse_exited.connect(func (): 
		swap.material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	
	swap_tempest(TempestManager.TempestType.SNOW_TRAIL)

func swap_tempest(tempest: TempestManager.TempestType) -> void:
	generate_cans(tempest)
	pop_shelf()
	swap.texture_normal = TEMPEST_ARROWS[tempest]
	
	selected_panel.material.set_shader_parameter("replacement_colors", [PANEL_COLOURS[tempest]])
	selected_tempest_label.add_theme_color_override("font_color", TEXT_COLOURS[tempest])
	selected_tempest_label.text = TempestManager.TempestType.find_key(tempest)\
		.to_lower().replace("_", ' ')
	selected_tempest_texture.texture = TEMPEST_SPRITES[tempest]
	
	if tempest == TempestManager.TempestType.SNOW_TRAIL:
		swap.pressed.connect(func (): 
			swap_tempest(TempestManager.TempestType.HAILSTORM), CONNECT_ONE_SHOT)
	else:
		
		swap.pressed.connect(func (): 
			swap_tempest(TempestManager.TempestType.SNOW_TRAIL), CONNECT_ONE_SHOT)

func generate_cans(tempest: TempestManager.TempestType) -> void:
	grid_container.get_children().map(func (x): x.queue_free())
	
	var outline = ShaderMaterial.new()
	outline.shader = WHITE_OUTLINE
	
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(TempestManager.TempestType.find_key(tempest)) 
	
	for i in range(SHELF_COLUMNS * SHELF_ROWS):
		var new_can = TextureButton.new()
		new_can.texture_normal = CANS[rng.randi_range(0, CANS.size() - 1)]
		grid_container.add_child(new_can)
		
		new_can.material = outline.duplicate()
		new_can.material.set_shader_parameter("outline_color", OUTLINE_COLOUR)
		new_can.material.set_shader_parameter("original_colors", ORIGINAL_COLOURS)
		
		new_can.material.set_shader_parameter("replacement_colors", 
			replacement_colours[rng.randi_range(0, replacement_colours.size() - 1)].get_array())
		new_can.mouse_entered.connect(func (): hover_can(new_can))
		new_can.mouse_exited.connect(func (): off_hover_can(new_can))
		
		@warning_ignore("integer_division")
		var row = i / SHELF_COLUMNS
		var column = i % SHELF_ROWS
		var rows = snow_trail_rows if tempest == TempestManager.TempestType.SNOW_TRAIL else hailstorm_rows
		if rows.size() > row:
			if rows[row].upgrades.size() >= column:
				new_can.set_meta("tempest", tempest)
				new_can.set_meta("upgrade", snow_trail_rows[row].upgrades[column])

func hover_can(can: TextureButton) -> void:
	can.material.set_shader_parameter("outline_color", Color.WHITE)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	
	if !can.has_meta("upgrade"): return
	
	var u = can.get_meta("upgrade") as TempestUpgrade
	var t = can.get_meta("tempest")
	description_text.text = TempestManager.format_desc(t, u.stat, u.amount, u.operation)
	price_text.text = AMAZONITE_PATH + str(u.cost)
	
	description_text.add_theme_color_override("default_color", TEXT_COLOURS[t])
	price_text.add_theme_color_override("default_color", TEXT_COLOURS[t])
	description_panel.material.set_shader_parameter("replacement_colors", [PANEL_COLOURS[t]])
	price_panel.material.set_shader_parameter("replacement_colors", [PANEL_COLOURS[t]])
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(description, "position:y", 150, 0.3)

func off_hover_can(can: TextureButton) -> void:
	can.material.set_shader_parameter("outline_color", OUTLINE_COLOUR)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.tween_property(description, "position:y", 190, 0.3)

func pop_shelf() -> void:
	var t = create_tween()
	t.tween_property(shelves, "scale", Vector2.ONE * 1.1, 0.1)
	t.tween_property(shelves, "scale", Vector2.ONE * 0.9, 0.08)
	t.tween_property(shelves, "scale", Vector2.ONE, 0.025)
