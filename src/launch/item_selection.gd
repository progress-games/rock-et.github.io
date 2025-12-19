extends Control

const TWEEN_SCALE := 1.2
const TWEEN_DUR := 0.3
const DESELECTED := Color(1, 1, 1, 0.2)
const SELECTED := Color.WHITE
const MAX_CAPACITY := 4
const SELECTED_ITEM := Color(0.8, 0.4, 0.23, 1)
const EMPTY_ITEM := Color(0.43, 0.15, 0.15, 1)
const HOVER_ITEM := Color.WHITE
const LEVEL_POS := Vector2(26, 26)
const FONT_COLOUR := Color(0.18, 0.13, 0.18, 1)
const JASON_DISABLED := Color(0, 0, 0, 0.4)

@onready var items := $Items/MarginContainer/GridContainer
@onready var spaces := $Capacity/MarginContainer/HBoxContainer
@onready var question_mark = load("res://merchant/items/question_mark.png")
var sprites: Dictionary[String, Texture]
var tweens: Dictionary[String, Tween]
var current_capacity := 2
var item_order: Array[String] # used for popping items

func _ready() -> void:
	var items_dict = GameManager.player.all_items
	
	for n in items_dict.keys():
		sprites[n] = load("res://merchant/items/" + n + ".png")
	
	# unlock_all()
	show_items()
	update_capacity()
	
	GameManager.state_changed.connect(func (s): if s == Enums.State.LAUNCH: show_items(); update_capacity())
	hide_description()

func unlock_all() -> void:
	for item in GameManager.player.all_items.keys():
		GameManager.player.owned_items.set(item, GameManager.player.all_items[item])

func show_items() -> void:
	for node in items.get_children():
		node.queue_free()
	
	for item in GameManager.player.all_items.keys():
		var texture_rect = TextureRect.new()
		
		if GameManager.player.owned_items.get(item):
			texture_rect.set_meta("item_name", item)
			texture_rect.mouse_entered.connect(func (): on_hover(texture_rect))
			texture_rect.mouse_exited.connect(func (): off_hover(texture_rect))
			texture_rect.gui_input.connect(func(e: InputEvent):
				if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
					selected(texture_rect))
			texture_rect.texture = sprites[item]
			texture_rect.z_index = 5
			if !GameManager.player.equipped_items.get(item):
				texture_rect.modulate = Color(1, 1, 1, 0.2)
			
			var level_label = Label.new()
			level_label.text = str(GameManager.player.owned_items[item].level)
			level_label.add_theme_font_override("font", load("res://common/fonts/two pixels wide.ttf"))
			level_label.position = LEVEL_POS
			level_label.add_theme_color_override("font_color", Color.WHITE)
			level_label.add_theme_font_size_override("font_size", 6)
			
			texture_rect.add_child(level_label)
		else:
			texture_rect.texture = question_mark
		
		items.add_child(texture_rect)
		texture_rect.pivot_offset = texture_rect.size / 2
	
	for i in range(2):
		var texture_rect = TextureRect.new()
		texture_rect.texture = question_mark
		items.add_child(texture_rect)

func on_hover(rect: TextureRect) -> void:
	var item = rect.get_meta("item_name")
	if tweens.get(item):
		tweens[item].stop()
	
	tweens.set(item, create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))
	tweens.get(item).tween_property(rect, "scale", Vector2(TWEEN_SCALE, TWEEN_SCALE), TWEEN_DUR)
	show_description(rect)
	
	update_capacity(true)

func off_hover(rect: TextureRect) -> void:
	var item = rect.get_meta("item_name")
	if tweens.get(item):
		tweens[item].stop()
	
	tweens.set(item, create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	tweens.get(item).tween_property(rect, "scale", Vector2(1, 1), TWEEN_DUR)
	hide_description()
	update_capacity()

func selected(rect: TextureRect) -> void:
	var item = rect.get_meta("item_name")
	
	if GameManager.player.has_equipped(item):
		GameManager.player.unequip_item(item)
		rect.modulate = DESELECTED
		item_order.erase(item)
	elif len(GameManager.player.equipped_items) < current_capacity:
		GameManager.player.equip_item(item)
		rect.modulate = SELECTED
		item_order.append(item)
	else:
		var last = item_order.pop_back()
		GameManager.player.unequip_item(last)
		GameManager.player.equip_item(item)
		rect.modulate = SELECTED
		for node in items.get_children():
			if node.get_meta("item_name", "") == last:
				node.modulate = DESELECTED
		
		item_order.append(item)
	
	update_capacity()

func update_capacity(hovering: bool = false) -> void:
	for node in spaces.get_children():
		node.queue_free()
	
	var current_selected = len(GameManager.player.equipped_items)
	
	for i in range(MAX_CAPACITY):
		var texture_rect = TextureRect.new()
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		
		if i < current_capacity:
			texture_rect.texture = load("res://launch/item panel/circle.png")
			
			if (i == current_selected and hovering) or \
			(current_selected == current_capacity and hovering and i + 1 == current_selected):
				texture_rect.modulate = HOVER_ITEM
			elif i < current_selected:
				texture_rect.modulate = SELECTED_ITEM
			else:
				texture_rect.modulate = EMPTY_ITEM
		else:
			texture_rect.texture = load("res://launch/item panel/locked.png")
		
		spaces.add_child(texture_rect)

func show_description(rect: TextureRect) -> void:
	var item = rect.get_meta("item_name")
	$DescriptionPanel.visible = true
	$DescriptionText.visible = true
	$DescriptionText.text = GameManager.player.all_items[item].get_description()
	
func hide_description() -> void:
	$DescriptionPanel.visible = false
	$DescriptionText.visible = false
