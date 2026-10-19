extends Control

#idgaf
const TEXT_SPEED = 0.02

const BOOST_BUTTON_POS = Vector2(230, 4)
const BOOST_BUTTON_SIZE = Vector2(84, 166)

@onready var item_selection: Control = $"../LogicManager/ItemSelection"
@onready var items: GridContainer = $"../LogicManager/ItemSelection/Items/MarginContainer/GridContainer"
@onready var boost_panel: Node2D = $"../LogicManager/Boost"
@onready var boost_display: BoostDisplay = $"../LogicManager/Boost/BoostDisplay"
@onready var fake_button: Button = $FakeButton
@onready var fake_button_2: Button = $FakeButton2

@onready var capacity: MarginContainer = $"../LogicManager/ItemSelection/Capacity"

@onready var item_labels: Array[Label] = [
	$Item, 
	$Item2, 
	$Item3
]

@onready var next: Button = $Next

@onready var boost: Label = $Boost

var listen_for_equip: bool = false

func _ready() -> void:
	hide()
	check_for_updates()
	GameManager.state_changed.connect(func (s): 
		if s == Enums.State.LAUNCH: check_for_updates())

func check_for_updates() -> void:
	if !GameManager.tutorial_progress.has(Enums.Tutorial.EQUIP_ITEM):
		start_item_tutorial()
	
	if !GameManager.tutorial_progress.has(Enums.Tutorial.BOOST):
		show_boost()

func hide_text(label: Label) -> void:
	var t = create_tween()
	t.tween_property(label, "modulate:a", 0., .5)
	t.finished.connect(label.hide)

func tween_text(label: Label) -> Tween:
	label.show()
	var target = label.text
	label.text = ""
	
	var t = create_tween()
	t.tween_property(label, "text", target, TEXT_SPEED * target.length())
	
	return t

#func _process(delta: float) -> void:
	#if !listen_for_equip: return
	#if items.get_child_count() <= 9:
		#show_equip_item()
		#listen_for_equip = false

func start_item_tutorial() -> void:
	if GameManager.player.owned_items.size() == 0: 
		return
	
	show()
	GameManager.read_tutorial(Enums.Tutorial.EQUIP_ITEM)
	
	var t = tween_text(item_labels[0])
	t.finished.connect(
		func ():
			next.show()
			next.pressed.connect(show_equip_item, CONNECT_ONE_SHOT)
	)
	
func show_equip_item() -> void:
	hide_text(item_labels[0])
	next.hide()
	tween_text(item_labels[1])
	
	var i = items.get_children().find_custom(
		func (x):
			return x.has_meta("item_name")
	)
	
	var item = items.get_child(i)
	
	item.z_index = 9
	item.modulate = Color.WHITE
	fake_button.set_meta("item", item.get_meta("item_name"))
	
	fake_button.global_position = items.global_position + Vector2(
		(i % 3) * (item.size.x + 4),
		floor(i / 3.) * (item.size.y + 4)
	)
	
	fake_button.size = item.size
	
	fake_button.mouse_entered.connect(item_selection.get_by_name(fake_button.get_meta("item")).mouse_entered.emit)
	fake_button.mouse_exited.connect(item_selection.get_by_name(fake_button.get_meta("item")).mouse_exited.emit)
	fake_button.pressed.connect(
		func ():
			item.z_index = 0
			show_item_equip_capacity(), CONNECT_ONE_SHOT)

func show_item_equip_capacity() -> void:
	item_selection.selected(item_selection.get_by_name(fake_button.get_meta("item")))
	hide_text(item_labels[1])
	var t = tween_text(item_labels[2])
	
	capacity.z_index = 9
	
	t.finished.connect(
		func ():
			next.text = "done!"
			next.show()
	)
	
	next.pressed.connect(
		func ():
			next.hide()
			capacity.z_index = 0
			next.text = "next >>"
			item_labels[2].hide()
			hide(),
		CONNECT_ONE_SHOT
	)

func show_boost() -> void:
	if !GameManager.player.has_discovered_mineral(Enums.Mineral.CORUNDUM): 
		return
	
	boost.show()
	show()
	
	GameManager.read_tutorial(Enums.Tutorial.BOOST)
	
	boost_panel.z_index = 7
	fake_button_2.position = BOOST_BUTTON_POS
	fake_button_2.size = BOOST_BUTTON_SIZE
	
	fake_button_2.mouse_entered.connect(boost_display.ship_slider.mouse_entered.emit)
	fake_button_2.mouse_exited.connect(boost_display.ship_slider.mouse_exited.emit)
	
	fake_button_2.button_down.connect(
		func ():
			boost_panel.z_index = 0
			hide()
			boost.hide(), CONNECT_ONE_SHOT
	)
