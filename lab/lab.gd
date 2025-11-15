extends Node2D

const SPEED := 10
const PANELS: Dictionary[String, PackedScene] = {
	"strength": preload("res://lab/panels/strength/strength_panel.tscn"),
	"lightning": preload("res://lab/panels/lightning/lightning_panel.tscn"),
	"locked": preload("res://lab/panels/locked/locked_panel.tscn")
}
const PANEL_ORDER: Array[String] = ["strength", "lightning"]
const PANEL_MINERALS: Array[Enums.Mineral] = [Enums.Mineral.TOPAZ, Enums.Mineral.KYANITE]
const TWEEN_DUR := 0.3
const PANEL_POSITION := Vector2(189, 75)

var panel_idx := -1
var tweens: Dictionary[String, Tween] = {}
@onready var nodes: Dictionary[String, Node] = {
	"back": $BackButton,
	"next": $NextButton,
	"panel": $Panel
}

func _ready() -> void:
	next_panel()
	GameManager.clear_inventory.emit()
	GameManager.player.mineral_discovered.connect(func (): next_panel(0))

func tween_scale(_name: String, value: float, dur: float = TWEEN_DUR) -> void:
	if tweens.get(_name) != null:
		tweens.get(_name).stop()
	
	tweens.set(_name, create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT))
	tweens.get(_name).tween_property(nodes.get(_name), "scale", Vector2(value, value), dur)

func next_panel(direction: int = 1) -> void:
	GameManager.clear_inventory.emit()

	panel_idx = (panel_idx + direction) % len(PANEL_ORDER)
	
	GameManager.show_mineral.emit(PANEL_MINERALS[panel_idx])
	
	nodes.panel.queue_free()
	
	var new_panel: Node
	
	if GameManager.player.has_discovered_mineral(PANEL_MINERALS[panel_idx]):
		new_panel = PANELS.get(PANEL_ORDER[panel_idx]).instantiate()
	else:
		new_panel = PANELS.get("locked").instantiate()
		new_panel.mineral = PANEL_MINERALS[panel_idx]
	
	nodes.panel = new_panel
	nodes.panel.position = PANEL_POSITION
	nodes.panel.scale = Vector2(1.1, 1.1)
	
	tweens.panel = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tweens.panel.tween_property(new_panel, "scale", Vector2(1, 1), TWEEN_DUR)
	
	add_child(new_panel)

func _on_back_button_pressed() -> void:
	next_panel(-1)

func _on_next_button_pressed() -> void:
	next_panel()


##### visual things: ignore

func _on_next_button_button_down() -> void:
	tween_scale("next", 1.1)
func _on_next_button_button_up() -> void:
	tween_scale("next", 1)
func _on_next_button_mouse_entered() -> void:
	nodes.next.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func _on_next_button_mouse_exited() -> void:
	nodes.next.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func _on_back_button_mouse_entered() -> void:
	nodes.back.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func _on_back_button_mouse_exited() -> void:
	nodes.back.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func _on_back_button_button_down() -> void:
	tween_scale("back", 1.1)
func _on_back_button_button_up() -> void:
	tween_scale("back", 1)
