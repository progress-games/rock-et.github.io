extends MarginContainer

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

var input_names = [
	"potion slot 1",
	"potion slot 2",
	"potion slot 3"
]

# uhuh uhuh yeah im listening
@onready var waiting: ColorRect = $"../../../Waiting"

var input_binding: String

func _ready() -> void:
	for i in buttons.size():
		buttons[i].pressed.connect(func (): wait_for(input_names[i]))
	update_keys()

func update_keys() -> void:
	var joystick = Input.get_connected_joypads().size() > 0
	for i in keys.size():
		keys[i].visible = !joystick
		joystick_buttons[i].visible = joystick
		
		# idx refers to the id of joystick
		var joystick_idx = 0 if InputMap.action_get_events(input_names[i])[0].as_text().begins_with("J") else 1
		var key_idx = 1 if joystick_idx == 0 else 0
		
		if !joystick:
			keys[i].text = InputMap.action_get_events(input_names[i])[key_idx].as_text().left(1)
		else:
			var event_name = InputMap.action_get_events(input_names[i])[joystick_idx].as_text().left(15)
			if JOYPAD_SPRITES.has(event_name):
				joystick_buttons[i].texture = JOYPAD_SPRITES.get(event_name)
			else:
				keys[i].visible = true
				joystick_buttons[i].visible = false
				keys[i].text = InputMap.action_get_events(input_names[i])[joystick_idx].as_text().left(10)
			
func wait_for(n: String) -> void:
	waiting.show()
	input_binding = n

func _input(event: InputEvent) -> void:
	if waiting.visible && event.is_pressed():
		var joystick = Input.get_connected_joypads().size() > 0
		var joystick_idx = 0 if InputMap.action_get_events(input_binding)[0].as_text().begins_with("J") else 1
		var checking_idx = joystick_idx if joystick else abs(joystick_idx - 1)
		
		InputMap.action_erase_event(input_binding, InputMap.action_get_events(input_binding)[checking_idx])
		InputMap.action_add_event(input_binding, event)
		waiting.hide()
		update_keys()
