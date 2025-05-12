extends TextureButton

@onready var details: Dictionary[String, Node] = {
	"titleBG": $TitleBG,
	"title": $Title,
	"mineral": $Mineral,
	"costBG": $CostBG,
	"cost": $Cost
}
@export var stat_name: String
@export var drop_height: int
@export var text_colour: Color
@export var bg_colour: Color
@export var text_offset: Vector2
@export var disables: bool
@export var mineral_enabled: Texture2D
@export var mineral_disabled: Texture2D
@export var hover_outline: bool = true;

var disabled_text_colour := Color('#694f62')
var disabled_bg_colour := Color('#c7dcd0')

@onready var stat := GameManager.player.get_stat(stat_name)

func _ready() -> void:
	_set_cost()
	GameManager.add_mineral.connect(func(_mineral, _amount): _set_cost())
	details.get("title").text = stat.name
	details.get("titleBG").text = stat.name
	material = material.duplicate()
	
	if GameManager.player.can_upgrade_stat(stat_name) or not disables:
		_enable_button()
	else:
		_disable_button()
	
	for key in details:
		details.get(key).position += text_offset
	
func _on_mouse_entered() -> void:
	if hover_outline:
		material.set_shader_parameter("width", 1)

func _on_mouse_exited() -> void:
	if hover_outline:
		material.set_shader_parameter("width", 0)

func _on_button_down() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	for key in details:
		details.get(key).position.y += drop_height

func _on_button_up() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_UP)
	for key in details:
		details.get(key).position.y -= drop_height

func _set_cost() -> void:
	if GameManager.player.get_stat(stat_name).is_max():
		details["costBG"].text = "MAX LVL"
		details["cost"].text = "MAX LVL"
		return
	
	details["costBG"].text = stat.display_cost
	details["cost"].text = stat.display_cost
	
	if GameManager.player.can_upgrade_stat(stat_name) or not disables:
		_enable_button()
	else:
		_disable_button()

func _disable_button() -> void:
	disabled = true
	details.get("cost").modulate = disabled_text_colour
	details.get("title").modulate = disabled_text_colour
	
	details.get("costBG").modulate = disabled_bg_colour
	details.get("titleBG").modulate = disabled_bg_colour
	
	details.get("mineral").texture = mineral_disabled

func _enable_button() -> void:
	disabled = false
	details.get("cost").modulate = text_colour
	details.get("title").modulate = text_colour
	
	details.get("costBG").modulate = bg_colour
	details.get("titleBG").modulate = bg_colour
	
	details.get("mineral").texture = mineral_enabled

func _on_pressed() -> void:
	if GameManager.player.can_upgrade_stat(stat_name):
		GameManager.add_mineral.emit(stat.cost.mineral, -1 * stat.cost.amount)
		GameManager.player.upgrade_stat(stat_name)
	_set_cost()
