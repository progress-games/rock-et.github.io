extends Node2D

	
		#if d != 1: SaveManager.store_save("day"+str(d)))
	
	#GameManager.read_state_dialogue.connect(func (_s):
		#if !SaveManager.save_exists("day"+str(GameManager.day)):
			#SaveManager.store_save("day"+str(GameManager.day))
		#)
	
	# for saving, could change managed_states to a dict.
	# c is an append function
	#SaveManager.get_managed_states.connect(func (a: Array):
		#for m in managed_states: 
			#a.append(m)
	#)
	#SaveManager.set_managed_states.connect(func (a: Dictionary):
		#for m in managed_states:
			#var s = a[Enums.State.find_key(m.state)]
			#if s:
				#if s.revealed:
					#_reveal_state(m, false)
		#_day_changed_managed_states(GameManager.day))
	
	#$ReduceClicking.visible = true

const ACTION_REQUIRED = preload("uid://cp3hdb2ae714y")
const NEW_THING = preload("uid://bpneumlrmil3l")
const SPEECH_REQUIRED = preload("uid://c24djhnyam8on")
const POPUP_TIME = 0.3

const SPEED := 10
const SCREEN_CENTER := Vector2(0, 0)
const DIRECTIONS := {
	ManagedState.Direction.RIGHT: Vector2(320, 0),
	ManagedState.Direction.DOWN: Vector2(0, 180),
	ManagedState.Direction.LEFT: Vector2(-320, 0)
}
const WHITE_OUTLINE := preload("res://common/shaders/white_outline.gdshader")

@export var default_planet: Enums.Planet

@export var clicky_positions: Array[Vector2]

@onready var main_camera: Camera2D = $MainCamera
@onready var paused: ColorRect = $MainCamera/Paused

# disable these for demo mode
@onready var settings: TextureButton = $Background/Kruos/StateButtons/Settings
@onready var embark: TextureButton = $Background/Kruos/StateButtons/Embark
@onready var alfheim: TextureButton = $Background/Kruos/StateButtons/Alfheim

# disable these for kruos demo mode
@onready var embark_vulcan: TextureButton = $Background/Vulcan/StateButtons/Embark
@onready var floatie: TextureButton = $Background/Vulcan/StateButtons/Floatie
@onready var amy: TextureButton = $Background/Vulcan/StateButtons/Amy
@onready var settings_vulcan: TextureButton = $Background/Vulcan/StateButtons/Settings

var scenes := {
	"mission": preload("res://mission/mission.tscn")
}

@export var skip_opening: bool = false
@export var skip_tutorial: bool = false
@export var loading_save: bool = false
@export var demo_mode: bool = false
@export var managed_states: Array[ManagedState]
@onready var opening: Node2D = $Background/Opening

# merchant spawns every 4 days
var next_merchant_date := -1

var active_state: ManagedState

func _ready() -> void:
	if skip_opening:
		opening.load_save = loading_save
		opening.default_planet = default_planet
		opening.skip_opening.call_deferred()
	
	SaveManager.request_next_merchant_day.connect(func (): SaveManager.save.next_merchant_day = next_merchant_date)
	SaveManager.loaded_save.connect(_setup_managed_states)

func activate_demo_mode() -> void:
	if !demo_mode: return
	
	if GameManager.planet == Enums.Planet.DYRT:
		embark.disabled = true
		settings.disabled = true
		alfheim.disabled = true
		return
	
	if GameManager.planet == Enums.Planet.KRUOS:
		embark_vulcan.disabled = true
		floatie.disabled = true
		amy.disabled = true
		settings_vulcan.disabled = true

func _state_changed(new_state: Enums.State) -> void:
	close_active_popup()
	
	if new_state == Enums.State.MISSION:
		GameManager.clear_inventory.emit()
		if !main_camera.get_children().any(func (x): return x.has_meta("mission")):
			var new_mission = scenes.get("mission").instantiate()
			# new_mission.weights = GameManager.weights
			main_camera.add_child(new_mission)
			new_mission.set_meta("mission", true)
			GameManager.set_mouse_state.emit(Enums.MouseState.MISSION)
			GameManager.set_inventory.emit(Enums.InventoryState.MISSION, true)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.TAKE_OFF)

func new_save() -> void:
	SaveManager.new_save()

func store_save() -> void:
	SaveManager.store_save()

func load_save() -> void:
	SaveManager.load_save()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit") && !GameManager.pause_locked:
		if get_tree().paused:
			GameManager.play.emit()
		else:
			GameManager.pause.emit()
		paused.visible = get_tree().paused

func delete_all_signal_connections(managed_state: ManagedState):
	var b = get_node(managed_state.state_button) as TextureButton
	var signals = ["mouse_exited", "mouse_entered"]
	for s in signals:
		var sig = b.get_signal_connection_list(s)
		for c in sig:
			b.disconnect(s, c.callable)

func _day_changed_managed_states(day: int) -> void:
	for managed_state in managed_states:
		if managed_state.state == Enums.State.CLICKY && managed_state.revealed:
			get_node(managed_state.state_button).position = \
				clicky_positions.pick_random() if !Settings.get_setting(Settings.SettingType.CLICKY_LOCK)\
				else clicky_positions[0]
		(get_node(managed_state.state_button)).visible = _should_show_state(managed_state, day)
		if _should_show_state(managed_state, day) != managed_state.revealed and !managed_state.revealed:
			_reveal_state(managed_state)

func _reveal_state(managed_state: ManagedState, yellow_outline: bool = true) -> void:
	GameManager.state_revealed.emit(managed_state.state)
	
	managed_state.revealed = true
	var button = get_node(managed_state.state_button) as TextureButton
	
	# add indicator
	var new_thing = Sprite2D.new()
	new_thing.texture = NEW_THING
	var button_image = button.texture_normal.get_image()
	new_thing.position = Vector2(
		button_image.get_width() / 2,
		button_image.get_height() / 2 - button_image.get_used_rect().size.y / 2 - 10
	)
	new_thing.z_index = 1
	new_thing.visible = yellow_outline
	button.add_child(new_thing)
	
	# set up yellow outline 
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

## shows state from requirement object
func _should_show_state(managed_state: ManagedState, day: int) -> bool:
	if managed_state.show_requirement == null:
		return true
	
	var req = managed_state.show_requirement
	
	match req.requirement_type:
		Requirement.RequirementType.DAY:
			return day >= req.day
		Requirement.RequirementType.MINERAL:
			return GameManager.player.has_discovered_mineral(req.mineral)
		_: # custom
			return _custom_show_state(managed_state, day)

func _custom_show_state(managed_state: ManagedState, day: int) -> bool:
	match managed_state.state:
		Enums.State.MERCHANT:
			var show_merchant = day == next_merchant_date and GameManager.player.has_discovered_state(Enums.State.EXCHANGE)
			if next_merchant_date == day - 1: 
				next_merchant_date += 4 if StatManager.get_stat("stall_level").level < 4 else 2
			return show_merchant
		Enums.State.EXCHANGE:
			var show_exchange = get_node(managed_state.state_button).visible or \
				GameManager.player.has_discovered_state(Enums.State.EXCHANGE) or \
				GameManager.player.minerals.values().any(func (x): return x >= 200)
			## if we're showing it and we haven't shown the merchant yet and the merchant isn't meant to be shown today
			if show_exchange && !GameManager.player.has_discovered_state(Enums.State.MERCHANT) &&\
			next_merchant_date != day: 
				next_merchant_date = day + 4
			return show_exchange
		Enums.State.ALFHEIM:
			return StatManager.get_stat("unlocked_powerups").level > 1
		Enums.State.BUNKER:
			return GameManager.active_blizzard
	
	return true

func _show_popup(managed_state: ManagedState) -> bool:
	if managed_state.popup_requirement == null: return true
	
	var req = managed_state.popup_requirement
	
	match req.requirement_type:
		Requirement.RequirementType.MINERAL:
			return GameManager.player.has_discovered_mineral(req.mineral)
		Requirement.RequirementType.DAY:
			return GameManager.day > req.day
		Requirement.RequirementType.CUSTOM:
			match GameManager.planet:
				Enums.Planet.DYRT:
					return (GameManager.player.has_discovered_mineral(Enums.Mineral.CORUNDUM) || \
							len(GameManager.player.owned_items) > 0 ||
							len(GameManager.player.owned_potions) > 0) 
				Enums.Planet.KRUOS:
					return StatManager.get_stat("unlocked_powerups").level > 1
				Enums.Planet.VULCAN:
					return DroneManager.owned_drones.size() > 1 || DroneManager.drone_shape.unlocked_tiles
	return true

func close_active_popup() -> void:
	if active_state == null:
		return
	
	var t = create_tween()
	var p = get_node(active_state.popup)
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(p, "position", DIRECTIONS.get(active_state.popup_direction), POPUP_TIME)

func _update_managed_state(managed_state: ManagedState) -> void:
	close_active_popup()
	
	if _show_popup(managed_state):
		AudioManager.create_audio(managed_state.sound_effect)
		active_state = managed_state
		
		var t = create_tween()
		var p = get_node(active_state.popup)
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t.tween_property(p, "position", SCREEN_CENTER, POPUP_TIME)
		return
	
	GameManager.state_changed.emit(managed_state.popup_requirement.redirection)

func setup_connections() -> void:
	GameManager.state_changed.connect(_state_changed)
	GameManager.day_changed.connect(_day_changed_managed_states)
	
	GameManager.planet_changed.emit(default_planet)
	GameManager.music_changed.emit(default_planet)
	
	GameManager.demo_mode = demo_mode
	
	if skip_tutorial:
		for v in Enums.Tutorial.values(): GameManager.read_tutorial(v)

func _setup_managed_states() -> void:
	var white_outline = ShaderMaterial.new()
	white_outline.shader = WHITE_OUTLINE
	
	next_merchant_date = SaveManager.save.next_merchant_day
	
	for managed_state in managed_states:
		var popup = get_node(managed_state.popup)
		popup.position = DIRECTIONS.get(managed_state.popup_direction)
		
		var state_button = get_node(managed_state.state_button) as TextureButton
		var state_data = SaveManager.save.states[managed_state.state]
		
		managed_state.revealed = state_data.revealed
		
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(state_button.texture_normal.get_image(), 0.5)
		state_button.texture_click_mask = bitmap
		state_button.hide()
		
		state_button.material = white_outline.duplicate()
		state_button.material.set_shader_parameter("width", 0)
		
		state_button.pressed.connect(func ():
			state_button.focus_mode = Control.FOCUS_NONE
			GameManager.clear_inventory.emit()
			GameManager.show_mineral.emit(managed_state.mineral)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			GameManager.state_changed.emit(managed_state.state)
			_update_managed_state(managed_state)
			GameManager.set_inventory.emit(Enums.InventoryState.LOCKED, managed_state.fade_inventory))
		
		if !managed_state.revealed:
			continue
		
		state_button.mouse_entered.connect(func ():
			state_button.material.set_shader_parameter("width", 1)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER))
		state_button.mouse_exited.connect(func ():
			state_button.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))
	
	
	_day_changed_managed_states(GameManager.day)
	setup_connections()
