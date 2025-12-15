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
	
	GameManager.day_changed.connect(func(d):
		_day_changed_managed_states(d))
		#if d != 1: SaveManager.store_save("day"+str(d)))
	
	# for saving, could change managed_states to a dict.
	# c is an append function
	SaveManager.get_managed_states.connect(func (a: Array):
		for m in managed_states: 
			a.append(m)
	)
	SaveManager.set_managed_states.connect(func (a: Dictionary):
		for m in managed_states:
			var s = a[Enums.State.find_key(m.listening_state)]
			if s:
				if s.revealed:
					_reveal_state(m, false)
				m.read_dialogue = s.read_dialogue
		_day_changed_managed_states(GameManager.day))
	
	$ReduceClicking.visible = true
	
	for managed_state in managed_states:
		get_node(managed_state.state_button).visible = false
	
	_setup_managed_states()
	#if SaveManager.save_exists("day30"):
	#	SaveManager.load_save("day30")
	#else:
	_day_changed_managed_states(GameManager.day)
	# print(OS.get_data_dir())
	SaveManager.loading_save = false

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

func delete_all_signal_connections(managed_state: ManagedState):
	var b = get_node(managed_state.state_button) as TextureButton
	var signals = ["mouse_exited", "mouse_entered"]
	for s in signals:
		var sig = b.get_signal_connection_list(s)
		for c in sig:
			b.disconnect(s, c.callable)

func _day_changed_managed_states(day: int) -> void:
	for managed_state in managed_states:
		(get_node(managed_state.state_button)).visible = _should_show_state(managed_state, day)
		if _should_show_state(managed_state, day) != managed_state.revealed and !managed_state.revealed:
			_reveal_state(managed_state)

func _reveal_state(managed_state: ManagedState, yellow_outline: bool = true) -> void:
	managed_state.revealed = true
	
	# add indicator
	var new_thing = Sprite2D.new()
	new_thing.texture = load("res://home/new_thing.png")
	new_thing.position = managed_state.new_thing_pos
	new_thing.z_index = 0
	new_thing.visible = yellow_outline
	add_child(new_thing)
	
	# set up yellow outline 
	var button = get_node(managed_state.state_button) as TextureButton
	button.material.set_shader_parameter("color", Color("fbff86") if yellow_outline else Color.TRANSPARENT)
	button.material.set_shader_parameter("width", 1)
	
	button.mouse_entered.connect(func ():
		button.material.set_shader_parameter("color", Color.WHITE)
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER))
	
	button.mouse_exited.connect(func ():
		button.material.set_shader_parameter("color", Color("fbff86") if yellow_outline else Color.TRANSPARENT)
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	
	# after being pressed once, turn this back into a normal button
	button.pressed.connect(func (): 
		# turn into normal button
		button.material.set_shader_parameter("color", Color.WHITE)
		new_thing.queue_free()
		delete_all_signal_connections(managed_state)
		# give signals
		button.mouse_entered.connect(func ():
			button.material.set_shader_parameter("width", 1)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER))
		button.mouse_exited.connect(func ():
			button.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
		, CONNECT_ONE_SHOT)

func _should_show_state(managed_state: ManagedState, day: int) -> bool:
	if managed_state.requirement_type == ManagedState.Requirement.DAY and day < managed_state.day_requirement:
		return false
	
	if managed_state.requirement_type == ManagedState.Requirement.MINERAL and \
	!GameManager.player.has_discovered_mineral(managed_state.mineral_requirement):
		return false
	
	match managed_state.listening_state:
		Enums.State.MERCHANT:
			return day % 7 == 0 and GameManager.player.has_discovered_state(Enums.State.EXCHANGE)
		Enums.State.EXCHANGE:
			return get_node(managed_state.state_button).visible or \
				GameManager.player.minerals.values().any(func (x): return x >= 100)
		_:
			return true
	
	return true

func _update_managed_states(state: Enums.State) -> void:
	for managed_state in managed_states:
		if managed_state.read_dialogue and get_node_or_null(str(managed_state.popup) + "/SpeechBubble"):
			get_node(str(managed_state.popup) + "/SpeechBubble").queue_free()
		managed_state.read_dialogue = get_node_or_null(str(managed_state.popup) + "/SpeechBubble") == null
		if managed_state.listening_state == state:
			if !GameManager.player.has_discovered_state(managed_state.requirement) or \
			(managed_state.listening_state == Enums.State.LAUNCH and \
			!(GameManager.player.has_discovered_state(Enums.State.BLEEG) or len(GameManager.player.owned_items) > 0)):
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
		state_button.z_index = -1
		
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(state_button.texture_normal.get_image(), 0.5)
		state_button.texture_click_mask = bitmap
		
		state_button.material = white_outline.duplicate()
		state_button.material.set_shader_parameter("width", 0)
		
		state_button.pressed.connect(func ():
			state_button.focus_mode = Control.FOCUS_NONE
			GameManager.clear_inventory.emit()
			GameManager.show_mineral.emit(managed_state.mineral)
			GameManager.state_changed.emit(managed_state.emitted_state)
			GameManager.set_inventory.emit(Enums.InventoryState.LOCKED, managed_state.fade_inventory)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
