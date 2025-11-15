extends Control

@onready var items := $Items/MarginContainer/GridContainer
@onready var question_mark = load("res://merchant/items/question_mark.png")
var sprites: Array

func _ready() -> void:
	var items_dict = GameManager.player.all_items
		
	for name in items_dict.keys():
		sprites[name] = load("res://merchant/items/" + name + ".png")

func show_items() -> void:
	for node in items.get_children():
		node.queue_free()
	
	for item in GameManager.player.all_items.keys():
		var texture_rect = TextureRect.new()
		
		
		if GameManager.player.owned_items.get(item):
			texture_rect.texture = sprites[item]
		else:
			texture_rect.texture = question_mark
