extends Resource
class_name StateData

@export var discovered: bool = false
@export var revealed: bool = false

## the number up to which we've read dialogue
## eg 0 -> we haven't read any
## 1 -> we've read the first item, et.c
@export var dialogue_progress: int = -1
