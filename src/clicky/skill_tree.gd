extends Control

@onready var nodes := $Nodes
@onready var lines := $Lines

func _ready() -> void:
	draw_dependencies()

func draw_dependencies() -> void:
	for node in nodes.get_children():
		for d in node.dependencies:
			var l = Line2D.new()
			l.width = 2
			l.z_index = -2
			l.add_point(node.position + node.pivot_offset_ratio * node.size)
			l.add_point(d.position + d.pivot_offset_ratio * d.size)
			lines.add_child(l)

func _process(delta: float) -> void:
	lines.get_children().map(func (x): x.queue_free())
	draw_dependencies()
