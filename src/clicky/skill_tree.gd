extends Control

@onready var nodes := $Nodes
@onready var lines := $Lines
@onready var locked_gradient: Line2D = $LockedGradient
@onready var locked_gradient_2: Line2D = $LockedGradient2
@onready var root: SkillNode = $Nodes/Root
@onready var autoclick: Control = $Nodes/Autoclick
@onready var blackhole: Control = $Nodes/Blackhole
@onready var explosion: Control = $Nodes/Explosion

var skills: Array[Control]
var loaded := false


func _ready() -> void:
	skills = [root]
	skills.append_array(autoclick.get_children())
	skills.append_array(blackhole.get_children())
	skills.append_array(explosion.get_children())
	
	SaveManager.get_unlocked_nodes.connect(func (d):
		d.set("root", root.level)
		d.set("autoclick", {})
		d.set("explosion", {})
		d.set("blackhole", {})
		for n in autoclick.get_children(): d.autoclick.set(n.id, n.level)
		for n in explosion.get_children(): d.explosion.set(n.id, n.level)
		for n in blackhole.get_children(): d.blackhole.set(n.id, n.level)
	)
	
	SaveManager.set_unlocked_nodes.connect(func (d):
		if loaded: return
		loaded = true
		
		for n in d.root: root.unlock()
		
		for node in d.autoclick.keys():
			var skill = autoclick.find_child("Autoclick" + node)
			for i in range(d.autoclick[node]):
				skill.unlock()
		
		for node in d.explosion.keys():
			var skill = explosion.find_child("Explosion" + node)
			for i in range(d.explosion[node]):
				skill.unlock()
		
		for node in d.blackhole.keys():
			var skill = blackhole.find_child("Blackhole" + node)
			for i in range(d.blackhole[node]):
				skill.unlock()
		)
	
	draw_dependencies()

func draw_dependencies() -> void:
	for node in skills:
		node.visible = !node.dependencies.all(func (x): return x.level == 0) or node.id == 0
	
	for node in skills:
		for d in node.dependencies:
			if !d.visible and !node.visible:
				continue
			
			var l = Line2D.new()
			l.width = 2
			l.z_index = -2
			l.add_point(node.position + node.pivot_offset_ratio * node.size)
			l.add_point(d.position + d.pivot_offset_ratio * d.size)
			
			# if dependency is not visible
			if !d.visible:
				l.texture = locked_gradient.texture
				l.texture_mode = locked_gradient.texture_mode
				l.gradient = locked_gradient_2.gradient
			# if this node is not visible
			elif !node.visible:
				l.gradient = locked_gradient.gradient
			# if the dependency is completed
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
	draw_all()#dependencies()

func _gui_input(event: InputEvent) -> void:
	SaveManager.store_save("test")
