extends TextureButton

@onready var details: Dictionary[String, Node] = {
	"title": $Title,
	"mineral": $Mineral,
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
@export var show_upgrade_name: bool = true;

var disabled_text_colour := Color('#694f62')
var disabled_bg_colour := Color('#c7dcd0')

@onready var stat := GameManager.player.get_stat(stat_name)

signal stat_changed()

func _ready() -> void:
	GameManager.add_mineral.connect(func(_mineral, _amount): _set_cost())
	details.title.text = stat.display_name
	tooltip_text = stat.tooltip
	material = material.duplicate()
	details.cost.material = details.cost.material.duplicate()
	details.title.material = details.title.material.duplicate()
	
	if !show_upgrade_name:
		details.title.visible = false
		text_offset.y -= 15
	
	for key in details:
		details.get(key).position += text_offset
	
	_set_cost()

func change_stat(new_stat_name: String) -> void:
	stat_name = new_stat_name
	stat = GameManager.player.get_stat(stat_name)
	tooltip_text = stat.tooltip
	details.title.text = stat.display_name
	_set_cost()
	stat_changed.emit()

func _on_mouse_entered() -> void:
	if hover_outline:
		material.set_shader_parameter("width", 1)
	
	if disabled: 
		GameManager.set_mouse_state.emit(GameManager.MouseState.DISABLED) 
	else: 
		GameManager.set_mouse_state.emit(GameManager.MouseState.HOVER)

func _on_mouse_exited() -> void:
	if hover_outline:
		material.set_shader_parameter("width", 0)
	
	GameManager.set_mouse_state.emit(GameManager.MouseState.DEFAULT)

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
		details["cost"].text = "MAX LVL"
		return
	
	details["cost"].text = stat.display_cost
	
	if GameManager.player.can_upgrade_stat(stat_name) or not disables:
		_enable_button()
	else:
		_disable_button()
		

func _enable_button() -> void:
	disabled = false
	details.cost.material.set_shader_parameter("outline_colour", bg_colour)
	details.title.material.set_shader_parameter("outline_colour", bg_colour)
	
	details.cost.material.set_shader_parameter("font_colour", text_colour)
	details.title.material.set_shader_parameter("font_colour", text_colour)
	
	details.mineral.texture = mineral_enabled
	size = texture_normal.get_size()

func _disable_button() -> void:
	disabled = true
	
	details.cost.material.set_shader_parameter("outline_colour", disabled_bg_colour)
	details.title.material.set_shader_parameter("outline_colour", disabled_bg_colour)
	
	details.cost.material.set_shader_parameter("font_colour", disabled_text_colour)
	details.title.material.set_shader_parameter("font_colour", disabled_text_colour)
	
	details.mineral.texture = mineral_disabled
	size = texture_disabled.get_size()

func _on_pressed() -> void:
	if GameManager.player.can_upgrade_stat(stat_name):
		GameManager.add_mineral.emit(stat.cost.mineral, -1 * stat.cost.amount)
		GameManager.player.upgrade_stat(stat_name)
	_set_cost()
