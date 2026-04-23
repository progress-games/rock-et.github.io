extends Control

const NEXT_NODE_GAP := 30
const COMPLETED_DEPENDENCY := Color(0.569, 0.859, 0.412, 1.0)
const INIT_UPGRADES := {
	ClickEffectManager.ClickType.AUTOCLICK: {
		"level": 8,
		"panel": preload("uid://drf0ygndjtvp8"),
		"tree": preload("uid://dddqb3cajxfbt")
		},
	ClickEffectManager.ClickType.EXPLOSION: {
		"level": 12,
		"panel": preload("uid://by48s48qe0hw0"),
		"tree": preload("uid://2ru6d4uv6x7")
		},
	ClickEffectManager.ClickType.BLACKHOLE: {
		"level": 7,
		"panel": preload("uid://cppv2rdqrb83t"),
		"tree": preload("uid://tceqpwh8pqk2")
		},
}

@onready var nodes: Control = $Nodes
@onready var root: SkillNode = $Nodes/Root
@onready var next: NinePatchRect = $Nodes/Next
@onready var lines: Node2D = $Lines
@onready var pick_three: Control = $Camera2D2/ColorRect/PickThree
@onready var next_outline: ColorRect = $Nodes/Next/Outline

## left-to-right
@onready var locked_gradient_LTR: Line2D = $LockedGradient
@onready var locked_gradient_RTL: Line2D = $LockedGradient2

@onready var pick_three_container: HBoxContainer = $Camera2D2/ColorRect/PickThree/HBoxContainer

@onready var autoclick: NinePatchRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Autoclick
@onready var explosion: NinePatchRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Explosion
@onready var blackhole: NinePatchRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Blackhole

@onready var autoclick_outline: ColorRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Autoclick/ColorRect
@onready var explosion_outline: ColorRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Explosion/ColorRect
@onready var blackhole_outline: ColorRect = $Camera2D2/ColorRect/PickThree/HBoxContainer/Blackhole/ColorRect

@onready var description: NinePatchRect = $Camera2D2/ColorRect/PickThree/Description
@onready var description_label: RichTextLabel = $Camera2D2/ColorRect/PickThree/Description/RichTextLabel

var trees: Array[SubTree]

"""
steps to make this work:

1. when root is bought, reveal ?
2. when root is full and ? clicked, reveal choose three
3. when choose three is selected, add autoclick scene to tree

"""

func _ready() -> void:
	# GameManager.add_mineral.emit(Enums.Mineral.QUARTZ, 1000000)
	next.visible = false
	root.set_base_price(17)
	root.bought.connect(setup_next)
	
	SaveManager.set_unlocked_nodes.connect(load_nodes)
	SaveManager.get_unlocked_nodes.connect(save_nodes)
	
	# setup next
	next.mouse_entered.connect(func (): next_outline.visible = true)
	next.mouse_exited.connect(func (): next_outline.visible = false)
	next.gui_input.connect(func (e): 
		if e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT: choose_one())
	
	# setup choices
	autoclick.set_meta("click_effect", ClickEffectManager.ClickType.AUTOCLICK)
	blackhole.set_meta("click_effect", ClickEffectManager.ClickType.BLACKHOLE)
	explosion.set_meta("click_effect", ClickEffectManager.ClickType.EXPLOSION)
	
	autoclick.mouse_entered.connect(func (): hovering(autoclick))
	explosion.mouse_entered.connect(func (): hovering(explosion))
	blackhole.mouse_entered.connect(func (): hovering(blackhole))
	
	autoclick.mouse_exited.connect(func (): hovering(autoclick, false))
	explosion.mouse_exited.connect(func (): hovering(explosion, false))
	blackhole.mouse_exited.connect(func (): hovering(blackhole, false))
	
	autoclick.gui_input.connect(func (e):
		if e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT: chose(autoclick))
	blackhole.gui_input.connect(func (e):
		if e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT: chose(blackhole))
	explosion.gui_input.connect(func (e):
		if e is InputEventMouseButton and e.is_pressed() and e.button_index == MOUSE_BUTTON_LEFT: chose(explosion))

func save_nodes(nodes) -> void:
	nodes.set("root", root.level)
	nodes.set("trees", [])
	for tree in trees:
		nodes.trees.append({
			"name": ClickEffectManager.ClickType.find_key(tree.sub_tree_name),
			"nodes": tree.get_nodes()
			})

func load_nodes(nodes) -> void:
	for i in range(nodes.get("root", 0)):
		root.unlock()
	
	var _trees = nodes.get("trees", [])
	for tree in _trees:
		var click_effect = ClickEffectManager.ClickType[tree.name]
		var button = pick_three_container.get_children().filter(func (x): return x.get_meta("click_effect") == click_effect).front()
		chose(button)
		trees.back().unlock_nodes(tree.nodes)
		
## move next box and make it visible
func setup_next() -> void:
	var pre = [root] if trees.size() == 0 else trees.back().final
	
	next.position = Vector2(
		pre.reduce(func (a, x): return max(a, x.position.x + x.size.x), 0) + NEXT_NODE_GAP,
		pre.reduce(func (a, x): return a + x.position.y, 0) / pre.size() - next.pivot_offset_ratio.y * next.size.y / 2
		)
	
	if trees.size() > 0: next.position.x += trees.back().position.x
	
	next.visible = true

## reveal "choose one" interface
func choose_one() -> void:
	var pre = [root] if trees.size() == 0 else trees.back().final
	if !pre.all(func (x): return x.level == x.levels):
		return
	
	pick_three.visible = true
	nodes.mouse_behavior_recursive = MOUSE_BEHAVIOR_DISABLED

## choose a "choose one" option
func chose(c: NinePatchRect) -> void:
	c.visible = false
	next.visible = false
	
	var u = INIT_UPGRADES[c.get_meta("click_effect")]
	ClickEffectManager.upgrade_effect(c.get_meta("click_effect"), ClickEffectManager.StatType.EVERY, u.level)
	
	var new_tree = u.tree.instantiate()
	new_tree.position = next.position
	new_tree.scale_prices(pow(50, trees.size()))
	trees.append(new_tree)
	nodes.add_child(new_tree)
	
	setup_next()
	
	pick_three.visible = false
	nodes.mouse_behavior_recursive = MOUSE_BEHAVIOR_ENABLED

## hovering over choose one option
func hovering(panel: NinePatchRect, hover: bool = true) -> void:
	if hover: GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	else: GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	
	match panel.get_meta("click_effect"):
		ClickEffectManager.ClickType.AUTOCLICK: autoclick_outline.visible = hover
		ClickEffectManager.ClickType.EXPLOSION: explosion_outline.visible = hover
		ClickEffectManager.ClickType.BLACKHOLE: blackhole_outline.visible = hover
	
	description.texture = INIT_UPGRADES[panel.get_meta("click_effect")].panel
	description.visible = hover
	description_label.text = "every " + str(INIT_UPGRADES[panel.get_meta("click_effect")].level) + \
		" [img=12]res://clicky/symbols/every.png[/img] spawn " + \
		"[img=11]res://clicky/symbols/" + ClickEffectManager.ClickType.find_key(panel.get_meta("click_effect")) + \
		".png[/img]"

## create a line between two skill nodes
func create_line(node1: NinePatchRect, node2: NinePatchRect, \
	line_type: SubTree.DependencyLine = SubTree.DependencyLine.ANGLED) -> Line2D:
	var l = Line2D.new()
	l.width = 2
	l.z_index = -2
	
	match line_type:
		SubTree.DependencyLine.ANGLED:
			l.add_point(node1.global_position + node1.pivot_offset_ratio * node1.size)
			l.add_point(node2.global_position + node2.pivot_offset_ratio * node2.size)
		SubTree.DependencyLine.STRAIGHT:
			l.add_point(node1.global_position + node1.pivot_offset_ratio * node1.size)
			l.add_point(Vector2(node2.global_position.x + node2.pivot_offset_ratio.x * node2.size.x,
				node1.global_position.y + node1.pivot_offset_ratio.y * node1.size.y))
			l.add_point(node2.global_position + node2.pivot_offset_ratio * node2.size)
	
	## when we call this with a skill node and ninepatch rect using "Next" obj
	if typeof(node1) != typeof(node2): return
	
	if !node1.visible and node2.visible:
		l.texture = locked_gradient_RTL.texture
		l.texture_mode = locked_gradient_RTL.texture_mode
		l.gradient = locked_gradient_LTR.gradient
	
	# if this node is not visible 
	elif !node2.visible and node1.visible:
		l.gradient = locked_gradient_RTL.gradient
	
	# if the dependency is completed
	elif node1.level == node1.levels:
		l.default_color = COMPLETED_DEPENDENCY
	
	return l

## draws subtree
func draw_tree(tree: SubTree) -> void:
	for node in tree.nodes:
		node.visible = !node.dependencies.all(func (x): return x.level == 0) or node == tree.first
	
	for node in tree.nodes:
		for dependency in node.dependencies:
			if !dependency.visible and !node.visible:
				continue
			
			lines.add_child(create_line(dependency, node, tree.dependency_lines))

## draw dependency lines between all nodes
func draw_dependencies() -> void:
	# delete all lines
	lines.get_children().map(func (x): x.queue_free())
	
	# no lines needed
	if root.level == 0:
		return
	 
	# connect root to the first tree
	if trees.size() == 0:
		lines.add_child(create_line(root, next))
		return
	
	var l = create_line(root, trees.front().first)
	l.default_color = COMPLETED_DEPENDENCY
	lines.add_child(l)
	
	for i in trees.size():
		var tree = trees[i]
		
		draw_tree(tree)
		
		var next_tree = null if trees.size() - 1 < i + 1 else trees[i + 1]
		
		if next_tree:
			for final in tree.final:
				lines.add_child(create_line(final, next_tree.first))
	
	next.visible = false
	if trees.size() < INIT_UPGRADES.size():
		for final in trees.back().final:
			if final.visible:
				next.visible = true
				lines.add_child(create_line(final, next))

func _process(_d: float) -> void:
	draw_dependencies()
