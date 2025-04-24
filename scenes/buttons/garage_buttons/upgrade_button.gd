extends TextureButton

@onready var details: Dictionary[String, Node] = {
	"titleBG": $TitleBG,
	"title": $Title,
	"mineral": $Mineral,
	"costBG": $CostBG,
	"cost": $Cost
}
var sprites = {
	"enabled": preload("res://assets/minerals/mineral.png"),
	"disabled": preload("res://assets/ui/amethyst_disabled.png")
}
@export var stat_name: String
@export var drop_height: int
@export var text_colour: Color
@export var bg_colour: Color

var disabled_text_colour := Color('#694f62')
var disabled_bg_colour := Color('#9babb2')

@onready var stat := GameManager.player.get_stat(stat_name)

func _ready() -> void:
	_set_cost()
	GameManager.add_mineral.connect(func(_mineral, _amount): _set_cost())
	details.get("title").text = stat.name
	details.get("titleBG").text = stat.name
	material = material.duplicate()

func _on_mouse_entered() -> void:
	material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	material.set_shader_parameter("width", 0)

func _on_button_down() -> void:
	for key in details:
		details.get(key).position.y += drop_height

func _on_button_up() -> void:
	for key in details:
		details.get(key).position.y -= drop_height

func _set_cost() -> void:
	details["costBG"].text = stat.display_cost
	details["cost"].text = stat.display_cost
	
	if GameManager.player.get_mineral(GameManager.Mineral.AMETHYST) < stat.cost:
		_disable_button()
	else:
		_enable_button()

func _disable_button() -> void:
	disabled = true
	details.get("cost").modulate = disabled_text_colour
	details.get("title").modulate = disabled_text_colour
	
	details.get("costBG").modulate = disabled_bg_colour
	details.get("titleBG").modulate = disabled_bg_colour
	
	details.get("mineral").texture = sprites.get("disabled")

func _enable_button() -> void:
	disabled = false
	details.get("cost").modulate = text_colour
	details.get("title").modulate = text_colour
	
	details.get("costBG").modulate = bg_colour
	details.get("titleBG").modulate = bg_colour
	
	details.get("mineral").texture = sprites.get("enabled")

func _on_pressed() -> void:
	GameManager.add_mineral.emit(GameManager.Mineral.AMETHYST, -1 * stat.cost)
	GameManager.player.upgrade_stat(stat_name)
	_set_cost()
