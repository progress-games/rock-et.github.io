extends Node2D

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

var stat_name: String

func _ready() -> void:
	upgrade_button.mouse_entered.connect(hovering)
	upgrade_button.mouse_exited.connect(off_hovering)
	
	stat_name = upgrade_button.stat_name
	GameManager.player.stat_upgraded.connect(update_text)
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
	
	update_text(Stat.new({"name": stat_name}))
	off_hovering()

func hovering() -> void:
	base.position = base_on_hover_location
	upgrade_arrow.show()
	upgrade.show()

func off_hovering() -> void:
	base.position = base_off_hover_location
	upgrade_arrow.hide()
	upgrade.hide()

func update_text(stat: Stat) -> void:
	if stat.name != stat_name:
		return
	
	base.text = GameManager.player.get_stat(stat_name).display_value
	upgrade.text = GameManager.player.get_stat(stat_name).next_level.display_value
	
	if texture is AtlasTexture:
		sprite.texture.set_region(Rect2((stat.level - 1) * region_size.x, 0, region_size.x, region_size.y))
