extends Control
class_name StatDisplay

@export var upgrade_button: TextureButton

## text off hover location
@export var base_off_hover_location: Vector2

## text on hover location
@export var base_on_hover_location: Vector2

## upgrade text location
@export var upgrade_location: Vector2

@export var sprite_pos: Vector2 = Vector2(-51, -3)
@export var region_size: Vector2
@export var texture: Texture
@export var font_colour: Color
@export var outline_colour: Color
@export var upgrade_font_colour: Color
@export var upgrade_outline_colour: Color
@export var upgrade_arrow_colour: Color
@export var font: FontFile = preload("uid://cmwv2cvr5llki")
@export var font_size: int = 16
@export var hide_upgrade_arrow: bool = false

@onready var base: Label = $Base
@onready var upgrade_arrow: TextureRect = $UpgradeArrow
@onready var upgrade: Label = $Upgrade
@onready var sprite: TextureRect = $Sprite


var stat: Stat

func _ready() -> void:
	upgrade_button.mouse_entered.connect(hovering)
	upgrade_button.mouse_exited.connect(off_hovering)
	
	stat = upgrade_button.stat if upgrade_button.stat else StatManager.get_stat(upgrade_button.stat_name)
	stat.upgraded.connect(update_text)
	
	refresh()
	
	upgrade_button.stat_changed.connect(func (): 
		stat.upgraded.disconnect(update_text)
		stat = StatManager.get_stat(upgrade_button.stat_name)
		stat.upgraded.connect(update_text)
		update_text()
	)
	off_hovering()

func refresh() -> void:
	base.material = base.material.duplicate()
	upgrade.material = upgrade.material.duplicate()
	upgrade_arrow.modulate = upgrade_arrow_colour
	
	sprite.set_position(sprite_pos)
	sprite.texture = texture
	
	base.material.set_shader_parameter("outline_colour", outline_colour)
	base.material.set_shader_parameter("font_colour", font_colour)
	base.add_theme_font_override("font", font)
	base.add_theme_font_size_override("font_size", font_size)
	
	upgrade.material.set_shader_parameter("outline_colour", upgrade_outline_colour)
	upgrade.material.set_shader_parameter("font_colour", upgrade_font_colour)
	upgrade.add_theme_font_override("font", font)
	upgrade.add_theme_font_size_override("font_size", font_size)
	
	upgrade.position += upgrade_location
	upgrade_arrow.position += upgrade_location
	
	update_text()

func hovering() -> void:
	base.position = base_on_hover_location
	if !hide_upgrade_arrow: upgrade_arrow.show()
	upgrade.show()

func off_hovering() -> void:
	base.position = base_off_hover_location
	upgrade_arrow.hide()
	upgrade.hide()

func update_text() -> void:
	# kinda jank but whatever
	if stat.stat_name.contains("portion"):
		base.text = str(StatManager.get_portion(stat.stat_name.replace("_portion", ""))) + "%"
		upgrade.text = str(min(100, StatManager.get_portion(stat.stat_name.replace("_portion", "")) + 3)) + "%"
	else:
		base.text = StatManager.get_stat(stat.stat_name).display_value
		upgrade.text = StatManager.get_stat(stat.stat_name).next_level.display_value
	
	if texture is AtlasTexture:
		sprite.texture.set_region(Rect2((stat.level - 1) * region_size.x, 0, region_size.x, region_size.y))
