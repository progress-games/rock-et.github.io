extends Resource
class_name MouseUI

enum Pos {
	ABOVE,
	BELOW,
	LEFT,
	RIGHT,
	CENTRE
}

enum Align {
	LEFT,
	CENTRE
}

@export var position: Pos
@export var align: Align
## updates every X frames
@export var update_rate: int = 0
## set the height or width depending on the position
@export var size: Vector2


var current_frame: int = 0
