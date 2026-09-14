extends MarginContainer

const KEY_IDX = 0
const JOYSTICK_IDX = 1

@onready var buttons: Array[TextureButton] = [
	$HBoxContainer/VBoxContainer3/TextureButton, 
	$HBoxContainer/VBoxContainer3/TextureButton2, 
	$HBoxContainer/VBoxContainer3/TextureButton3
]

@onready var keys: Array[Label] = [
	$HBoxContainer/VBoxContainer2/Label2, 
	$HBoxContainer/VBoxContainer2/Label3, 
	$HBoxContainer/VBoxContainer2/Label4
]

@onready var joystick_buttons: Array[TextureRect] = [
	$HBoxContainer/VBoxContainer2/TextureRect, 
	$HBoxContainer/VBoxContainer2/TextureRect2, 
	$HBoxContainer/VBoxContainer2/TextureRect3
]

const JOYPAD_SPRITES := {
	"Joypad Button 0": preload("uid://dqsnk00u84dof"),
	"Joypad Button 1": preload("uid://bmi7xwd1qul80"),
	"Joypad Button 2": preload("uid://bvh7g270uwybl"),
	"Joypad Button 3": preload("uid://cc3i7wy2156tn")
}

const SHORTHANDS := {
	"Shift": "Shift",
	"Tab": "Tab",
	"CapsLock": "CapsLock",
	"BracketRight": "]",
	"BracketLeft": "[",
	"Apostrophe": "'",
	"Semicolon": ";",
	"Comma": ",",
	"Period": ".",
	"Slash": "/",
	"Equal": "=",
	"BackSlash": "\\",
	"Minus": "-"
}

var input_names = [
	"potion slot 1",
	"potion slot 2",
	"potion slot 3"
]

# uhuh uhuh yeah im listening
@onready var waiting: ColorRect = $"../../../Waiting"

var input_binding: String
var checking_idx = 0

func _ready() -> void:
	for i in buttons.size():
		buttons[i].pressed.connect(func (): wait_for(input_names[i]))
	
	Settings.setting_updated.connect(
		func (s, v):
			match s:
				Settings.SettingType.USING_CONTROLLER: 
					checking_idx = JOYSTICK_IDX if v else KEY_IDX
				Settings.SettingType.POTION_KEYBINDINGS:
					for i in v.size():
						var event = InputEventKey.new()
						event.key_label = int(v[i])
						input_binding = input_names[i]
						update_binding(event, KEY_IDX, false)
				Settings.SettingType.POTION_CONTROLLER_BINDINGS:
					for i in v.size():
						var event = InputEventJoypadButton.new()
						event.button_index = int(v[i])
						input_binding = input_names[i]
						update_binding(event, JOYSTICK_IDX, false)
	)

## removes all event. adds the key and joystick event in that order
# old event stores the other 
func update_binding(event: InputEvent, idx: int = checking_idx, update_settings: bool = true) -> void:
	var key_input = InputMap.action_get_events(input_binding)[KEY_IDX]
	var joystick_input = InputMap.action_get_events(input_binding)[JOYSTICK_IDX]
	
	InputMap.action_erase_event(input_binding, key_input)
	InputMap.action_erase_event(input_binding, joystick_input)
	
	if idx == 0: # adding new key input
		InputMap.action_add_event(input_binding, event)
		InputMap.action_add_event(input_binding, joystick_input)
		if update_settings:
			var s = Settings.get_setting(Settings.SettingType.POTION_KEYBINDINGS)
			s[input_names.find(input_binding)] = event.key_label
			Settings.set_setting(Settings.SettingType.POTION_KEYBINDINGS, s)
	else:
		InputMap.action_add_event(input_binding, key_input)
		InputMap.action_add_event(input_binding, event)
		if update_settings:
			var s = Settings.get_setting(Settings.SettingType.POTION_CONTROLLER_BINDINGS)
			s[input_names.find(input_binding)] = event.button_index
			Settings.set_setting(Settings.SettingType.POTION_CONTROLLER_BINDINGS, s)
	
	waiting.hide()
	update_keys()

func update_input() -> void:
	keys.map(func (x): x.visible = !Settings.get_setting(Settings.SettingType.USING_CONTROLLER))
	joystick_buttons.map(func (x): x.visible = Settings.get_setting(Settings.SettingType.USING_CONTROLLER))
	if checking_idx == KEY_IDX:
		update_keys()
	else:
		update_controller()

func update_controller() -> void:
	for i in joystick_buttons.size():
		var event_name = InputMap.action_get_events(input_names[i])[JOYSTICK_IDX].as_text().left(15)
		if JOYPAD_SPRITES.has(event_name):
			joystick_buttons[i].texture = JOYPAD_SPRITES.get(event_name)
		else:
			keys[i].visible = true
			joystick_buttons[i].visible = false
			keys[i].text = InputMap.action_get_events(input_names[i])[JOYSTICK_IDX].as_text().left(10)

func event_to_text(e: InputEvent) -> String:
	var c = false
	var t = e.as_text()
	for shorthand in SHORTHANDS.keys():
		if t.begins_with(shorthand):
			t = SHORTHANDS[shorthand]
			c = true
			break
	return t if c else t.left(2).strip_edges()

func update_keys() -> void:
	for i in keys.size():
		keys[i].text = event_to_text(InputMap.action_get_events(input_names[i])[KEY_IDX])

func wait_for(n: String) -> void:
	waiting.show()
	input_binding = n

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("disallowed_keybindings") or event is InputEventScreenTouch:
		return
	
	if waiting.visible && event.is_pressed():
		update_binding(event)
