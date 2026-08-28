extends Area2D
class_name AmmoBox

const SHOW_OPENING := -12
const HIDDEN_OPENING := -3
const OPENING_WIDTH := 25

@onready var opening: ColorRect = $Opening
@onready var opening_progress: ColorRect = $Opening/OpeningProgress
@onready var box: Sprite2D = $Box

var progress: float = 0
var currently_opening: bool = false
var progress_hidden: bool = true

signal opened

func _ready() -> void:
	material = material.duplicate()
	area_entered.connect(func (_a): start_opening())
	area_exited.connect(func (_a): end_opening())

func start_opening() -> void:
	currently_opening = true
	progress_hidden = false
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(opening, "position:y", SHOW_OPENING, 0.2)
	
	box.material.set_shader_parameter("width", 1)

func end_opening() -> void:
	currently_opening = false
	box.material.set_shader_parameter("width", 0)

func hide_progress() -> void:
	progress_hidden = true
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(opening, "position:y", HIDDEN_OPENING, 0.2)

func _process(delta: float) -> void:
	if !progress_hidden:
		opening_progress.size.x = progress * OPENING_WIDTH
	
	if currently_opening:
		progress += delta
		if progress >= 1:
			opened.emit()
	elif !progress_hidden:
		progress -= delta * 2
		if progress <= 0:
			hide_progress()
	
