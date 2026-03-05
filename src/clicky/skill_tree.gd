extends Control

@onready var nodes := $Nodes
@onready var lines := $Lines
@onready var locked_gradient: Line2D = $LockedGradient
@onready var root: SkillNode = $Nodes/Root
@onready var autoclick: Control = $Nodes/Autoclick
@onready var blackhole: Control = $Nodes/Blackhole
@onready var explosion: Control = $Nodes/Explosion

var skills: Array[Control]


func _ready() -> void:
	skills = [root]
	skills.append_array(autoclick.get_children())
	skills.append_array(blackhole.get_children())
	skills.append_array(explosion.get_children())
	
	draw_dependencies()

func draw_dependencies() -> void:
	for node in skills:
		node.visible = !node.dependencies.all(func (x): return x.level == 0) or node.id == 0
	
	for node in skills:
		for d in node.dependencies:
			if !d.visible:
				continue
			var l = Line2D.new()
			l.width = 2
			l.z_index = -2
			l.add_point(node.position + node.pivot_offset_ratio * node.size)
			l.add_point(d.position + d.pivot_offset_ratio * d.size)
			if !node.visible:
				l.gradient = locked_gradient.gradient
			elif d.level == d.levels:
				l.default_color = Color(0.569, 0.859, 0.412, 1.0)
			lines.add_child(l)

func draw_all() -> void:
	for node in skills:
		node.visible = true
		for d in node.dependencies:
			var l = Line2D.new()
			l.width = 2
			l.z_index = -2
			l.add_point(node.position + node.pivot_offset_ratio * node.size)
			l.add_point(d.position + d.pivot_offset_ratio * d.size)
			lines.add_child(l)

func _process(delta: float) -> void:
	lines.get_children().map(func (x): x.queue_free())
	draw_all()
