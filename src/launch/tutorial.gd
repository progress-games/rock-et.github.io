extends Control

#idgaf

const BOOST_BUTTON_POS = Vector2(230, 4)
const BOOST_BUTTON_SIZE = Vector2(84, 166)

@onready var item_selection: Control = $"../LogicManager/ItemSelection"
@onready var items: GridContainer = $"../LogicManager/ItemSelection/Items/MarginContainer/GridContainer"
@onready var boost_panel: Node2D = $"../LogicManager/Boost"
@onready var boost_display: BoostDisplay = $"../LogicManager/Boost/BoostDisplay"
@onready var fake_button: Button = $FakeButton

@onready var equip_item: RichTextLabel = $Label
@onready var boost: RichTextLabel = $Label2

func _ready() -> void:
	#GameManager.player.owned_items.set("binoculars", GameManager.player.all_items.get("binoculars"))
	#item_selection.show_items()
	#item_selection.show()
	#show_equip_item()
	
	#GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, 1000)
	hide()
	check_for_updates()
	GameManager.state_changed.connect(func (_s): check_for_updates())

func check_for_updates() -> void:
	if !GameManager.tutorial_progress.has(Enums.Tutorial.EQUIP_ITEM):
		show_equip_item()
	
	if !GameManager.tutorial_progress.has(Enums.Tutorial.BOOST):
		show_boost()

func show_equip_item() -> void:
	if GameManager.player.owned_items.size() == 0: return
	
	equip_item.show()
	GameManager.tutorial_progress.append(Enums.Tutorial.EQUIP_ITEM)
	
	for i in items.get_child_count():
		var item = items.get_child(i)
		if item.has_meta("item_name"):
			item.z_index = 7
			item.modulate = Color.WHITE
			
			fake_button.global_position = item.global_position + (i % 3) * (item.size + Vector2(4, 4))
			fake_button.size = item.size
			
			fake_button.mouse_entered.connect(item.mouse_entered.emit)
			fake_button.mouse_exited.connect(item.mouse_exited.emit)
			fake_button.pressed.connect(func (): 
				item_selection.selected(item)
				hide()
				equip_item.hide()
				GameManager.tutorial_progress.append(Enums.Tutorial.EQUIP_ITEM), CONNECT_ONE_SHOT)
			
			break

func show_boost() -> void:
	if !GameManager.player.has_discovered_mineral(Enums.Mineral.CORUNDUM): return
	
	boost.show()
	GameManager.tutorial_progress.append(Enums.Tutorial.BOOST)
	
	boost_panel.z_index = 7
	fake_button.position = BOOST_BUTTON_POS
	fake_button.size = BOOST_BUTTON_SIZE
	
	fake_button.mouse_entered.connect(boost_display.ship_slider.mouse_entered.emit)
	fake_button.mouse_exited.connect(boost_display.ship_slider.mouse_exited.emit)
	
	fake_button.button_down.connect(
		func ():
			hide()
			boost.hide()
			GameManager.tutorial_progress.append(Enums.Tutorial.BOOST), CONNECT_ONE_SHOT
	)
