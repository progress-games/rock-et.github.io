extends Control

const EMPTY := Color(0.216, 0.306, 0.29, 1.0)
const SELECTED_ITEM := Color(0.573, 0.663, 0.518, 1.0)
const HOVER := Color(0.698, 0.729, 0.565, 1.0)
const CIRCLE = preload("uid://ctp0u7d2j72xr")
const LOCKED = preload("uid://cuxlh12gn7wbg")
const MAX_CAPACITY := 5
const TWEEN_SCALE := 1.2
const WHITE_OUTLINE = preload("uid://dstl4edni51y1")

var tweens: Dictionary[Powerup.PowerupType, Tween]
var powerups: Dictionary[Powerup.PowerupType, TextureRect]

@onready var powerup_container: GridContainer = $Powerups/GridContainer
@onready var capacity_container: VBoxContainer = $Capacity/VBoxContainer

func _ready() -> void:
	setup_items()
	update_capacity()
	
	StatManager.get_stat("unlocked_powerups").upgraded.connect(func (): 
		unlocked_powerup(StatManager.get_stat("unlocked_powerups").level - 1))
	
	unlocked_powerup(Powerup.PowerupType.SPEED_BOOST)
	powerups[Powerup.PowerupType.SPEED_BOOST].material.set_shader_parameter("width", 1)

func setup_items() -> void:
	powerup_container.get_children().map(func (x): x.queue_free())
	
	for p_enum in StatManager.powerup_order:
		var p = Powerup.PowerupType.find_key(p_enum)
		var tex: TextureRect = TextureRect.new()
		tex.texture = load("res://shikoba/assets/powerups/" + p.to_lower() + ".png")
		tex.pivot_offset_ratio = Vector2(0.5, 0.5)
		tex.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		tex.mouse_entered.connect(func (): on_hover(p_enum))
		tex.mouse_exited.connect(func (): off_hover(p_enum))
		tex.modulate = Color(0, 0, 0, 0.5)
		powerups[p_enum] = tex
		
		powerup_container.add_child(tex)

func unlocked_powerup(p: Powerup.PowerupType) -> void:
	var rect = powerups[p]
	
	rect.gui_input.connect(func (e: InputEvent): 
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
					select_powerup(p))
	
	rect.modulate = Color(1, 1, 1, 0.5)
	
	rect.material = ShaderMaterial.new()
	rect.material.shader = WHITE_OUTLINE
	rect.material.set_shader_parameter("width", 0)

func on_hover(p: Powerup.PowerupType) -> void:
	if tweens.get(p, null):
		tweens[p].kill()
	
	tweens[p] = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tweens[p].tween_property(powerups[p], "scale", Vector2.ONE * TWEEN_SCALE, 0.1)
	
	if powerups[p].material: update_capacity(true)

func off_hover(p: Powerup.PowerupType) -> void:
	tweens[p].kill()
	tweens[p] = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tweens[p].tween_property(powerups[p], "scale", Vector2.ONE, 0.1)
	
	if powerups[p].material: update_capacity()

func select_powerup(p: Powerup.PowerupType) -> void:
	var rect = powerups[p]
	
	if StatManager.enabled_powerups.has(p):
		StatManager.enabled_powerups.erase(p)
		rect.material.set_shader_parameter("width", 0)
	else:
		if StatManager.enabled_powerups.size() == int(ceil(StatManager.get_stat('powerup_capacity').value)):
			select_powerup(StatManager.enabled_powerups.back())
		
		StatManager.enabled_powerups.append(p)
		rect.material.set_shader_parameter("width", 1)
	
	update_capacity(true)

func update_capacity(hovering: bool = false) -> void:
	var current_selected = StatManager.enabled_powerups.size()
	var powerup_capacity = int(ceil(StatManager.get_stat('powerup_capacity').value))
	
	for i in range(MAX_CAPACITY):
		var tex: TextureRect = capacity_container.get_child(i)
		if i < powerup_capacity:
			tex.texture = CIRCLE
		else:
			tex.texture = LOCKED
		
		tex.modulate = SELECTED_ITEM if current_selected > i else EMPTY
		
		# if hovering and we're selecting the last item we have space for
		if hovering and ((current_selected == powerup_capacity and i == powerup_capacity - 1) or (current_selected != powerup_capacity and current_selected == i)):
			tex.modulate = HOVER
