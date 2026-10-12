extends Control

const UNLOCKED_COLOUR := Color(0.118, 0.737, 0.451, 1.0)
const LOCKED_COLOUR := Color(1.0, 1.0, 1.0, 0.3)

const DOTTED_LINE = preload("uid://dy8s3ox168yks")

@onready var tree: Control = $Tree
@onready var lines: Node2D = $Lines
@onready var root: StonehouseNode = $Tree/Root
@onready var camera_2d: Camera2D = $Camera2D

@onready var dependent_gradient: Gradient = $Locked.gradient
@onready var dependent_texture: Texture2D = $Locked.texture

# all lines that require this node to be unlocked to be deleted
var temporary_lines: Dictionary[StonehouseNode, Array]

signal node_selected(node: StonehouseNode)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	setup_nodes()
	root.visible = true
	
	#draw_all_lines()

func setup_nodes() -> void:
	var nodes = tree.get_children()
	
	for node in nodes:
		node.pressed.connect(func (): node_selected.emit(node))
		node.node_unlocked.connect(draw_dependencies.bind(node))
		node.visible = false

func tween_line_to_point(from: Vector2, to: Vector2) -> Tween:
	var line = Line2D.new()
	line.width = 2
	var direction = sign(from.y - to.y)
	
	lines.add_child(line)
	
	var t = create_tween()
	t.tween_method(func (p): 
		var curve = Curve2D.new()
		curve.add_point(from, Vector2.ZERO, Vector2(0, 5) * direction)
		curve.add_point(p, Vector2(0, -5) * direction, Vector2.ZERO)
		line.points = curve.get_baked_points(), 
		from, to, 0.8)
	
	return t

func draw_dependencies(upgraded_node: StonehouseNode) -> void:
	upgraded_node.modulate = Color.WHITE
	temporary_lines.get(upgraded_node, []).map(func (x): x.queue_free())
	
	for node in upgraded_node.next_nodes:
		var t = tween_line_to_point(
			upgraded_node.position + node.size / 2, 
			node.position + Vector2(1, 6))
		
		t.finished.connect(func (): 
			node.show()
			node.modulate = Color.WHITE
			
			var a = create_tween()
			a.tween_property(node, "modulate:a", 0.3, 0.4)
			
			create_dependent_lines(node))
		
		camera_2d.max_x = max(camera_2d.max_x, node.position.x)
		camera_2d.max_y = max(camera_2d.max_y, node.position.y)
		camera_2d.min_y = min(camera_2d.min_y, node.position.y)

func create_dependent_lines(node: StonehouseNode) -> void:
	for dependency in node.dependencies:
		if !dependency.unlocked:
			if !temporary_lines.has(dependency):
				temporary_lines.set(dependency, [])
			
			var line = Line2D.new()
			line.width = 2
			line.texture = dependent_texture
			line.gradient = dependent_gradient
			line.texture_mode = Line2D.LINE_TEXTURE_STRETCH
			line.points = [dependency.position + Vector2(1, 6), node.position + Vector2(1, 6)]
			temporary_lines[dependency].append(line)
			lines.add_child(line)

func draw_all_lines() -> void:
	var nodes = tree.get_children()
	
	for node in nodes:
		camera_2d.max_x = max(camera_2d.max_x, node.position.x)
		camera_2d.max_y = max(camera_2d.max_y, node.position.y)
		camera_2d.min_y = min(camera_2d.min_y, node.position.y)
		node.visible = true
		for dependency in node.dependencies:
			var line = Line2D.new()
			line.width = 1
			line.points = [node.position + node.size / 2, dependency.position + node.size / 2]
			lines.add_child(line)
		
		#for dependency in node.next_nodes:
			#var line = Line2D.new()
			#line.width = 1
			#line.points = [node.position + node.size / 2, dependency.position + node.size / 2]
			#lines.add_child(line)
	
