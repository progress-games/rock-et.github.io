extends Resource
class_name ManagedState

enum Direction {
	RIGHT,
	LEFT,
	DOWN
}

var revealed := false
var read_dialogue := false

# state button
@export var state_button: NodePath
@export var state: Enums.State
var sound_effect: SoundEffect.SOUND_EFFECT_TYPE = SoundEffect.SOUND_EFFECT_TYPE.SWOOSH
@export var mineral: Enums.Mineral
@export var planets: Dictionary[Enums.Planet, Vector2]

@export var show_requirement: Requirement
@export var popup_requirement: Requirement

# ui
@export var fade_inventory: bool
@export var popup: NodePath
@export var popup_direction: Direction

func _init() -> void:
	if popup_direction != Direction.LEFT: popup_direction = Direction[Direction.keys().pick_random()]
	GameManager.read_state_dialogue.connect(func (s): 
		read_dialogue = read_dialogue or s == state)
