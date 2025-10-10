extends Node2D

const SPEED := 10
const SCREEN_CENTER := Vector2(0, 0)
const DIRECTIONS := {
	ManagedState.Direction.RIGHT: Vector2(320, 0),
	ManagedState.Direction.DOWN: Vector2(0, 180),
	ManagedState.Direction.LEFT: Vector2(-320, 0)
}
const WHITE_OUTLINE := preload("res://common/shaders/white_outline.gdshader")

@onready var main_camera: Camera2D = $MainCamera
var scenes := {
	"mission": preload("res://mission/mission.tscn")
}

@export var managed_states: Array[ManagedState]

func _ready() -> void:
	GameManager.state_changed.connect(_state_changed)
	GameManager.show_mineral.emit(Enums.Mineral.AMETHYST)
	
	GameManager.day_changed.connect(_day_changed_managed_states)
	
	$ReduceClicking.visible = true
	
	_setup_managed_states()
	_day_changed_managed_states(GameManager.day)

func _state_changed(new_state: Enums.State) -> void:
	_update_managed_states(new_state)
	
	if new_state == Enums.State.MISSION:
		var new_mission = scenes.get("mission").instantiate()
		# new_mission.weights = GameManager.weights
		main_camera.add_child(new_mission)
		GameManager.set_mouse_state.emit(Enums.MouseState.MISSION)
		GameManager.set_inventory.emit(Enums.InventoryState.MISSION, true)
		GameManager.clear_inventory.emit()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.TAKE_OFF)

func _process(delta: float) -> void:
	_process_managed_states(delta)

func _day_changed_managed_states(day: int) -> void:
	for managed_state in managed_states:
		get_node(managed_state.state_button).visible = true # day >= managed_state.day_requirement

func _update_managed_states(state: Enums.State) -> void:
	for managed_state in managed_states:
		if managed_state.listening_state == state:
			if !GameManager.player.has_discovered_state(managed_state.requirement):
				GameManager.state_changed.emit(managed_state.redirect)
			else:
				AudioManager.create_audio(managed_state.sound_effect)
				var popup = get_node(managed_state.popup)
				popup.set_meta("target", SCREEN_CENTER)
		else:
			var popup = get_node(managed_state.popup)
			popup.set_meta("target", DIRECTIONS.get(managed_state.popup_direction))

func _process_managed_states(delta: float) -> void:
	for managed_state in managed_states:
		var popup = get_node(managed_state.popup)
		var target = popup.get_meta("target")
		if popup.position != target:
			popup.position += (target - popup.position) * delta * SPEED

func _setup_managed_states() -> void:
	var white_outline = ShaderMaterial.new()
	white_outline.shader = WHITE_OUTLINE
	
	for managed_state in managed_states:
		var popup = get_node(managed_state.popup)
		popup.set_meta("target", DIRECTIONS.get(managed_state.popup_direction))
		
		var state_button = get_node(managed_state.state_button) as TextureButton
		
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(state_button.texture_normal.get_image(), 0.5)
		state_button.texture_click_mask = bitmap
		
		state_button.material = white_outline.duplicate()
		state_button.material.set_shader_parameter("width", 0)
		
		state_button.pressed.connect(func ():
			GameManager.clear_inventory.emit()
			GameManager.show_mineral.emit(managed_state.mineral)
			GameManager.state_changed.emit(managed_state.emitted_state)
			GameManager.set_inventory.emit(Enums.InventoryState.LOCKED, managed_state.fade_inventory)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
		state_button.mouse_entered.connect(func ():
			state_button.material.set_shader_parameter("width", 1)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER))
		state_button.mouse_exited.connect(func ():
			state_button.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
