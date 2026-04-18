extends Control
class_name NewMineralPopup

const SWITCH_ALT: Dictionary[Enums.Mineral, Color] = {
	Enums.Mineral.GOLD: Color(1.0, 1.0, 1.0, 1.0),
	Enums.Mineral.QUARTZ: Color(0.18, 0.133, 0.184, 1.0)
}

@onready var margin_container: MarginContainer = $MarginContainer

@onready var new: RichTextLabel = $MarginContainer/MarginContainer/HBoxContainer/New
@onready var mineral_text: RichTextLabel = $MarginContainer/MarginContainer/HBoxContainer/MineralText
@onready var nine_patch_rect: NinePatchRect = $MarginContainer/NinePatchRect

func set_mineral(m: Enums.Mineral) -> void:
	nine_patch_rect.material.set_shader_parameter("replacement_colors", [
		GameManager.mineral_data[m].dark_colour, 
		GameManager.mineral_data[m].mid_colour])
	
	var mineral_name = Enums.Mineral.find_key(m).to_lower()
	mineral_text.text = "[img]res://common/minerals/" + mineral_name + ".png[/img][outline_size=1] " + mineral_name
	mineral_text.material.set_shader_parameter("colour", GameManager.mineral_data[m].dark_colour)
	
	size = margin_container.size
	custom_minimum_size = size
	
	if SWITCH_ALT.has(m):
		new.add_theme_color_override("default_color", SWITCH_ALT[m])
