extends Control

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const LOCKED = preload("uid://cuxlh12gn7wbg")
const CIRCLE = preload("uid://ctp0u7d2j72xr")

const FILLED_COLOUR = Color(0.192, 0.212, 0.22, 1.0)
const EMPTY_COLOUR = Color(0.329, 0.494, 0.392, 1.0)
const SELECTED_COLOUR = Color(0.573, 0.663, 0.518, 1.0)

@onready var potions: Array[TextureRect] = [
	$MarginContainer/MarginContainer/GridContainer/TextureRect, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect3, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect4, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect5, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect6, 
]

@onready var potion_counts: Array[Label] = [
	$MarginContainer/MarginContainer/GridContainer/TextureRect/Label, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect2/Label, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect3/Label, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect4/Label, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect5/Label, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect6/Label, 
]

@onready var owned_counts: Array[Label] = [
	$MarginContainer/MarginContainer/GridContainer/TextureRect/Label2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect2/Label2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect3/Label2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect4/Label2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect5/Label2, 
	$MarginContainer/MarginContainer/GridContainer/TextureRect6/Label2, 
]

@onready var capacity_tex: Array[TextureRect] = [
	$NinePatchRect/HBoxContainer/TextureRect, 
	$NinePatchRect/HBoxContainer/TextureRect2, 
	$NinePatchRect/HBoxContainer/TextureRect3
]
@onready var reset_potions: TextureButton = $ResetPotions

var selected: Array[String]

func _ready() -> void:
	#for i in range(2):
		#for p in GameManager.player.all_potions.values():
			#if randf() < 0.4: continue
			#GameManager.player.owned_potions.append(p.potion_name)
	
	$DescriptionPanel.visible = false
	$DescriptionText.visible = false
	
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.LAUNCH: 
			refresh_potions()
			selected.clear()
			refresh_potions()
			update_capacity()
	)
	
	setup_potions()
	refresh_potions()
	update_capacity()
	
	reset_potions.mouse_entered.connect(func (): 
		reset_potions.material.set_shader_parameter("width", 1)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	)
	reset_potions.mouse_exited.connect(func (): 
		reset_potions.material.set_shader_parameter("width", 0)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	)
	reset_potions.pressed.connect(func ():
		selected.clear()
		refresh_potions()
		update_capacity()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	)

func setup_potions() -> void:
	for i in range(GameManager.player.all_potions.keys().size()):
		var potion_name = GameManager.player.all_potions.keys()[i]
		var potion_type = GameManager.player.all_potions[potion_name]
		var potion = potions[i]
		
		potion.texture = potion_type.texture
		potion.set_meta("potion", potion_name)
		potion.gui_input.connect(func (e):
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				select_potion(potion_name))
		potion.mouse_entered.connect(func (): hovering_potion(i))
		potion.mouse_exited.connect(func (): off_hover_potion(i))
		potion.pivot_offset_ratio = Vector2(0.5, 0.5)

func refresh_potions() -> void:
	for i in range(potions.size()):
		var potion_name = potions[i].get_meta("potion")
		var potion = potions[i]
		
		var count = GameManager.player.owned_potions.count(potion_name)
		var s = selected.count(potion_name)
		
		owned_counts[i].visible = count != 0
		owned_counts[i].text = str(count)
		
		potion_counts[i].visible = s != 0
		potion_counts[i].text = str(s)
		
		if count == 0:
			potion.self_modulate = Color(0, 0, 0, 0.3)
		elif s == 0:
			potion.self_modulate = Color(1, 1, 1, 0.2)
			owned_counts[i].modulate = Color(1, 1, 1, 0.5)
		else:
			potion.self_modulate = Color.WHITE
			owned_counts[i].modulate = Color(1, 1, 1, 0.5)

func select_potion(potion_name: String) -> void:
	var capacity = StatManager.get_stat("potion_capacity").value
	
	if GameManager.player.owned_potions.count(potion_name) < 1 + selected.count(potion_name):
		return
	
	if selected.size() > capacity:
		var remove_idx := -1
		for i in range(selected.size()):
			if selected[i] != potion_name:
				remove_idx = i
				break
		if remove_idx != -1:
			selected.remove_at(remove_idx)
		else:
			selected.pop_front() # all entries are potion_name
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	selected.append(potion_name)
	GameManager.player.equipped_potions = selected
	refresh_potions()
	update_capacity()

func hovering_potion(potion_idx: int) -> void:
	var potion = potions[potion_idx]
	var potion_name = potion.get_meta("potion")
	
	if !GameManager.player.owned_potions.has(potion_name):
		return
	
	if potion.material: potion.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	update_capacity(true)
	
	$DescriptionPanel.visible = true
	$DescriptionText.visible = true
	$DescriptionText.text = "[color=#2e222f]" + GameManager.player.all_potions[potion_name].potion_name + \
		":[/color] " + GameManager.player.all_potions[potion_name].description

func off_hover_potion(potion_idx: int) -> void:
	var potion = potions[potion_idx]
	
	if potion.material: potion.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	update_capacity()
	
	$DescriptionPanel.visible = false
	$DescriptionText.visible = false

func update_capacity(hovering: bool = false) -> void:
	var capacity = int(ceil(StatManager.get_stat("potion_capacity").value))
	
	for i in range(capacity_tex.size()):
		var tex = capacity_tex[i]
		var a = i + 1
		tex.texture = CIRCLE if a <= capacity else LOCKED
		
		if hovering:
			if (selected.size() == capacity && a == 1) || (selected.size() < capacity && a == capacity):
				tex.modulate = SELECTED_COLOUR
		elif a <= selected.size() || a > capacity:
			tex.modulate = FILLED_COLOUR
		else:
			tex.modulate = EMPTY_COLOUR
