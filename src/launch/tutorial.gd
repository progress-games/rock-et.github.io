extends Control

#idgaf

const BOOST_BUTTON_POS = Vector2(230, 4)
const BOOST_BUTTON_SIZE = Vector2(84, 166)

@onready var item_selection: Control = $"../LogicManager/ItemSelection"
@onready var items: GridContainer = $"../LogicManager/ItemSelection/Items/MarginContainer/GridContainer"
@onready var boost_panel: Node2D = $"../LogicManager/Boost"
@onready var boost_display: BoostDisplay = $"../LogicManager/Boost/BoostDisplay"
@onready var fake_button: Button = $FakeButton
@onready var fake_button_2: Button = $FakeButton2

@onready var equip_item: RichTextLabel = $Label
@onready var boost: RichTextLabel = $Label2

func _ready() -> void:
	hide()
	check_for_updates()
	GameManager.state_changed.connect(func (s): if s == Enums.State.LAUNCH: check_for_updates())

func check_for_updates() -> void:
	if !GameManager.tutorial_progress.has(Enums.Tutorial.EQUIP_ITEM):
		show_equip_item.call_deferred()
	
	if !GameManager.tutorial_progress.has(Enums.Tutorial.BOOST):
		show_boost()

func show_equip_item() -> void:
	if GameManager.player.owned_items.size() == 0: return
	
	equip_item.show()
	show()
	GameManager.read_tutorial(Enums.Tutorial.EQUIP_ITEM)
	
	for i in items.get_child_count():
		var item = items.get_child(i)
		if !item.has_meta("item_name"):
			continue
		
		item.z_index = 7
		item.modulate = Color.WHITE
		fake_button.set_meta("item", item.get_meta("item_name"))
		
		fake_button.global_position = item.global_position + (i % 3) * (item.size + Vector2(4, 4))
		fake_button.size = item.size
		
		fake_button.mouse_entered.connect(item_selection.get_by_name(fake_button.get_meta("item")).mouse_entered.emit)
		fake_button.mouse_exited.connect(item_selection.get_by_name(fake_button.get_meta("item")).mouse_exited.emit)
		fake_button.pressed.connect(func (): 
			item_selection.selected(item_selection.get_by_name(fake_button.get_meta("item")))
			hide()
			equip_item.hide(), CONNECT_ONE_SHOT)
		break

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
