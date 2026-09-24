extends Control

const LINES = [
	"before we begin...",
	"you are about to play Kruos, the second planet in rock[et]...",
	"this demo is only available here on galaxy...",
	"I strongly recommend playing the first planet before Kruos...",
	"you can find it linked in the description...",
	"the galaxy community has been so invaluable in providing incredible feedback...",
	"so if you get a chance, please leave feedback via the in-game link or link in description!",
	"enjoy :)"
]

@onready var next: Button = $Next
@onready var label: Label = $HBoxContainer/MarginContainer2/MarginContainer/Label

var line_idx: int = -1

func _ready() -> void:
	next_line()
	next.pressed.connect(next_line)

func next_line() -> void:
	line_idx += 1
	
	if line_idx == LINES.size():
		queue_free()
		return
	
	if line_idx == LINES.size() - 1:
		next.text = "done!"
	
	label.text = ""
	next.hide()
	
	var t = create_tween()
	t.tween_property(label, "text", LINES[line_idx], 0.04 * LINES[line_idx].length())
	t.finished.connect(next.show)
