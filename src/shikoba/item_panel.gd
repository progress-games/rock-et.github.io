extends HBoxContainer
class_name PowerupPanel

const DEFAULT_THEME = preload("uid://cr6q3vlvjjgb7")

@export var powerup_type: Powerup.PowerupType

@onready var powerup_data: PowerupData = GameManager.powerup_data[powerup_type]
@onready var powerup_stat = Powerup.PowerupType.find_key(powerup_type).to_lower() + "_powerup"

@onready var upgrade_button: UpgradeButton = $UpgradeButton
@onready var stat_display: StatDisplay = $NinePatchRect/StatDisplay
@onready var nine_patch_rect: NinePatchRect = $NinePatchRect

func _ready() -> void:
	# nine patch
	nine_patch_rect.material = nine_patch_rect.material.duplicate()
	nine_patch_rect.material.set_shader_parameter("replacement_colors", [powerup_data.colours.dark, powerup_data.colours.mid])
	
	# stat display
	
	stat_display.texture = powerup_data.texture
	stat_display.font_colour = powerup_data.colours.dark
	stat_display.outline_colour = Color.TRANSPARENT
	stat_display.upgrade_colour = powerup_data.colours.light
	stat_display.hide_upgrade_arrow = true
	stat_display.tooltip_text = StatManager.get_stat(powerup_stat).tooltip.replace("VALUE", \
		str(ceil(StatManager.get_stat(powerup_stat).value)))
	
	stat_display.refresh()
	
	upgrade_button.change_stat(powerup_stat)
	upgrade_button.tooltip_text = ""
