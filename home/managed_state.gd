extends Resource
class_name ManagedState

enum Direction {
	RIGHT,
	LEFT,
	DOWN
}

@export var state_button: NodePath
@export var emitted_state: Enums.State
@export var sound_effect: SoundEffect.SOUND_EFFECT_TYPE
@export var mineral: Enums.Mineral
@export var day_requirement: int = 0

@export var fade_inventory: bool
@export var popup: NodePath
@export var listening_state: Enums.State
@export var requirement: Enums.State
@export var redirect: Enums.State
@export var popup_direction: Direction
