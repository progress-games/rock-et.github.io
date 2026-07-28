extends GPUParticles2D

@export var colours: Dictionary[String, Array]

@onready var bar: TextureRect = $SubViewport/Bar
@onready var label: Label = $SubViewport/Bar/Label

var colour: String

func _ready() -> void:
	if colour == "": return
	bar.material.set_shader_parameter("replacement_colors", colours[colour])
	label.add_theme_color_override("font_color", colours[colour][0])
	label.text = str(snappedf(StatManager.get_portion_power(colour, "damage"), 0.01)) + "x"
