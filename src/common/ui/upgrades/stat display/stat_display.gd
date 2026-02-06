extends Control

@export var upgrade_button: TextureButton
@export var base_off_hover_location: Vector2
@export var base_on_hover_location: Vector2
@export var upgrade_location: Vector2
@export var region_size: Vector2
@export var texture: Texture
@export var font_colour: Color
@export var outline_colour: Color
@export var upgrade_font_colour: Color
@export var upgrade_outline_colour: Color
@export var upgrade_arrow_colour: Color

@onready var base: Label = $Base
@onready var upgrade_arrow: Sprite2D = $UpgradeArrow
@onready var upgrade: Label = $Upgrade
@onready var sprite: Sprite2D = $Sprite

var stat: Stat

func _ready() -> void:
	upgrade_button.mouse_entered.connect(hovering)
	upgrade_button.mouse_exited.connect(off_hovering)
	
	stat = upgrade_button.stat if upgrade_button.stat else StatManager.get_stat(upgrade_button.stat_name)
	stat.upgraded.connect(update_text)
	base.material = base.material.duplicate()
	upgrade.material = upgrade.material.duplicate()
	upgrade_arrow.modulate = upgrade_arrow_colour
	sprite.texture = texture
	
	base.material.set_shader_parameter("outline_colour", outline_colour)
	base.material.set_shader_parameter("font_colour", font_colour)
	
	upgrade.material.set_shader_parameter("outline_colour", upgrade_outline_colour)
	upgrade.material.set_shader_parameter("font_colour", upgrade_font_colour)
	
	upgrade.position += upgrade_location
	upgrade_arrow.position += upgrade_location
	
	update_text()
	upgrade_button.stat_changed.connect(func (): 
		stat.upgraded.disconnect(update_text)
		stat = StatManager.get_stat(upgrade_button.stat_name)
		stat.upgraded.connect(update_text)
		update_text()
	)
	off_hovering()

func hovering() -> void:
	base.position = base_on_hover_location
	upgrade_arrow.show()
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
