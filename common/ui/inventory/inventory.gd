extends Node2D

const ROW_HEIGHT := 20
const ROW_WIDTH := 70
const BASE_HEIGHT := 6
const TOGGLE_HEIGHT := 24
const COUNTER_POS := Vector2(-14, 0)

var expanded: Array[Enums.Mineral] = []
var showing: Array[Enums.Mineral] = [
	Enums.Mineral.AMETHYST
]
var timers: Dictionary[Enums.Mineral, Timer] = {}
var rows: Dictionary[Enums.Mineral, Node] = {}
var expand_tween: Tween
var locked: bool = false

var mineral_counter: PackedScene = preload("res://common/ui/inventory/mineral_counter/mineral_counter.tscn")

var sprites: Dictionary[String, CompressedTexture2D] = {
	"row": preload("res://common/ui/inventory/assets/row.png"),
	"toggle_expand": preload("res://common/ui/inventory/assets/expand.png"),
	"toggle_collapse": preload("res://common/ui/inventory/assets/collapse.png"),
	"toggle_base": preload("res://common/ui/inventory/assets/toggle_base.png"),
	"base": preload("res://common/ui/inventory/assets/base.png")
}

@onready var base: Sprite2D = $Base
@onready var toggle_display: TextureButton = $Base/ToggleDisplay
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	toggle_display.set_meta("state", "expand")
	
	base.texture = sprites.base
	toggle_display.visible = false
	base.position.y -= (TOGGLE_HEIGHT - BASE_HEIGHT) / 2
	
	rows[Enums.Mineral.AMETHYST] = $Row
	
	GameManager.add_mineral.connect(_adapt_width)
	_adapt_width(null, null)
	
	GameManager.state_changed.connect(_state_changed)
	GameManager.show_mineral.connect(show_mineral)
	GameManager.hide_mineral.connect(hide_mineral)
	GameManager.hide_inventory.connect(func (): visible = false)
	GameManager.show_inventory.connect(func (): visible = true)

func _state_changed(state: Enums.State) -> void:
	match state:
		Enums.State.MISSION:
			modulate.a = 0.3
			locked = true
			_collapse()
		_:
			modulate.a = 1
			locked = false

func show_mineral(mineral: Enums.Mineral) -> void:
	if showing.has(mineral): return
	
	timers.set(mineral, null)
	
	showing.append(mineral)
	
	var new_counter = mineral_counter.instantiate()
	new_counter.mineral = mineral
	new_counter.position = Vector2(-14, 0)
	new_counter.update_width(mineral, 0)
	
	var new_row = Sprite2D.new()
	new_row.texture = sprites.row
	new_row.position = Vector2(ROW_WIDTH / 2, max(0, showing.size() - 1)*ROW_HEIGHT + ROW_HEIGHT / 2)
	new_row.add_child(new_counter)
	
	rows[mineral] = new_row
	add_child(new_row)
	base.position.y += ROW_HEIGHT
	collision_shape.position.y += ROW_HEIGHT / 2
	collision_shape.shape.size.y += ROW_HEIGHT
	
	_adapt_width(null, null)

func hide_mineral(mineral: Enums.Mineral) -> void:
	if not showing.has(mineral):
		return
	showing.erase(mineral)
	remove_child(rows[mineral])
	base.position.y -= ROW_HEIGHT
	collision_shape.position.y -= ROW_HEIGHT / 2
	collision_shape.shape.size.y -= ROW_HEIGHT
	
	_adapt_width(null, null)

func _adapt_width(_m = Enums.Mineral.AMETHYST, _a = 0) -> void:
	var width := 0.0
	
	if toggle_display.visible:
		width = ROW_WIDTH
	
	for mineral in rows:
		var row = rows.get(mineral)
		width = max(width, min(70, row.get_child(0).get_width()))
	
	for mineral in rows:
		rows.get(mineral).position.x = ROW_WIDTH / 2 - (ROW_WIDTH - width)
		rows.get(mineral).get_child(0).position.x = COUNTER_POS.x + (ROW_WIDTH - width)
	
	base.position.x = ROW_WIDTH / 2 - (ROW_WIDTH - width)

func _on_toggle_display_pressed() -> void:
	if toggle_display.get_meta("state") == "expand":
		toggle_display.set_meta("state", "collapse")
		toggle_display.texture_normal = sprites.toggle_collapse
		_expand()
		
	else:
		toggle_display.set_meta("state", "expand")
		toggle_display.texture_normal = sprites.toggle_expand
		_collapse()
		

func _expand() -> void:
	for _name in Enums.Mineral.keys():
		var mineral = Enums.Mineral[_name]
		if not showing.has(mineral):
			expanded.append(mineral)
			show_mineral(mineral)

func _collapse() -> void:
	for mineral in expanded:
		hide_mineral(mineral)
	
	expanded = []

func get_mineral_position(mineral: Enums.Mineral):
	return Vector2(15, showing.find(mineral) * (max(0, showing.size() - 1)*ROW_HEIGHT + ROW_HEIGHT / 2))

func _on_toggle_display_mouse_entered() -> void:
	toggle_display.material.set_shader_parameter("width", 1)

func _on_toggle_display_mouse_exited() -> void:
	toggle_display.material.set_shader_parameter("width", 0)

func _on_mouse_entered() -> void:
	if locked: return
	
	base.texture = sprites.toggle_base
	base.position.y += (TOGGLE_HEIGHT - BASE_HEIGHT) / 2
	toggle_display.visible = true
	_adapt_width(null, null)

func _on_mouse_exited() -> void:
	if locked: return
	
	base.texture = sprites.base
	base.position.y -= (TOGGLE_HEIGHT - BASE_HEIGHT) / 2 
	toggle_display.visible = false
	_adapt_width(null, null)
