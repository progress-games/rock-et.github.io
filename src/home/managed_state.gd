extends Resource
class_name ManagedState

enum Direction {
	RIGHT,
	LEFT,
	DOWN
}

enum Requirement {
	MINERAL,
	DAY
}

var revealed := false
var read_dialogue := false

@export var state_button: NodePath
@export var emitted_state: Enums.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE
@export var mineral: Enums.Mineral
@export var day_requirement: int = 0
@export var mineral_requirement: Enums.Mineral
@export var requirement_type: Requirement
@export var new_thing_pos: Vector2

@export var fade_inventory: bool
@export var popup: NodePath
@export var listening_state: Enums.State
@export var requirement: Enums.State
@export var redirect: Enums.State
@export var popup_direction: Direction
