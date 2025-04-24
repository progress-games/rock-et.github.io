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
const DROP = 7
@onready var stat := GameManager.player.get_stat("fuel_capacity")

func _ready() -> void:
	_set_cost()
	GameManager.add_mineral.connect(func(_mineral, _amount): _set_cost())

func _on_mouse_entered() -> void:
	material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	material.set_shader_parameter("width", 0)

func _on_button_down() -> void:
	for key in details:
		details.get(key).position.y += DROP

func _on_button_up() -> void:
	for key in details:
		details.get(key).position.y -= DROP

func _set_cost() -> void:
	details["costBG"].text = stat.display_cost
	details["cost"].text = stat.display_cost
	
	if GameManager.player.get_mineral(GameManager.Mineral.AMETHYST) < stat.cost:
		_disable_button()
	else:
		_enable_button()

func _disable_button() -> void:
	disabled = true
	details.get("cost").modulate = Color('#694f62')
	details.get("title").modulate = Color('#694f62')
	
	details.get("costBG").modulate = Color('#9babb2')
	details.get("titleBG").modulate = Color('#9babb2')
	
	details.get("mineral").texture = sprites.get("disabled")

func _enable_button() -> void:
	disabled = false
	details.get("cost").modulate = Color('#6e2727')
	details.get("title").modulate = Color('#6e2727')
	
	details.get("costBG").modulate = Color('#f57d4a')
	details.get("titleBG").modulate = Color('#f57d4a')
	
	details.get("mineral").texture = sprites.get("enabled")

func _on_pressed() -> void:
	GameManager.add_mineral.emit(GameManager.Mineral.AMETHYST, -1 * stat.cost)
	GameManager.player.upgrade_stat("fuel_capacity")
	_set_cost()
