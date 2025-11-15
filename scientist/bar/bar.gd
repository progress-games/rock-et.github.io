extends Button

@export var colour: String

const TEXT_COLOUR : Dictionary[String, Color] = {
	"red": Color("EA4F36"),
	"orange": Color("FBFF86"),
	"green": Color("FBFF86"),
	"blue": Color("FFFFFF")
}

var is_pressed: bool = false

func _ready() -> void:
	mouse_entered.connect(func (): $Outline.visible = true)
	mouse_exited.connect(func (): $Outline.visible = true)
	$NinePatchRect.texture = load("res://scientist/bar/bar_" + colour + ".png")
	_set_portion()

func _set_portion() -> void:
	var portion: int = GameManager.player.get_portion(colour)
	$Label.text = str(portion)
	$Label.add_theme_color_override("font_color", TEXT_COLOUR[colour])
	size_flags_stretch_ratio = portion 
	
	$Label.visible = portion >= 5

func _was_selected(selected: String) -> void:
	if selected != colour:
		is_pressed = false
		$Outline.visible = false
		modulate = Color(1, 1, 1, 0.5)
	else:
		is_pressed = true
		$Outline.visible = true
		modulate = Color(1, 1, 1, 1)
