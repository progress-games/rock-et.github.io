extends Node2D

const ITEM_AMOUNT := 3
const PRICE_VIS := Vector2(122, 71)
const PRICE_HIDDEN := Vector2(122, 120)
const BASE_ROLL := 3

var item_stock: Array[String]
var sprites: Dictionary
var items: Dictionary
var price_tween: Tween
var roll_price: float

func _ready() -> void:
	items = GameManager.player.all_items
	
	for name in items.keys():
		sprites[name] = load("res://merchant/items/" + name + ".png")
	
	roll()
	
	$RollButton.mouse_entered.connect(func (): on_hover($RollButton))
	$RollButton.mouse_exited.connect(func (): off_hover($RollButton))
	$RollButton.pressed.connect(pay_for_roll)
	GameManager.day_changed.connect(func (x): roll_price = BASE_ROLL; $RollButton/Align/Price.text = str(int(roll_price)))

func pay_for_roll() -> void:
	if GameManager.can_afford(roll_price, Enums.Mineral.GOLD):
		GameManager.add_mineral.emit(Enums.Mineral.GOLD, roll_price)
		roll_price *= 1.5
		$RollButton/Align/Price.text = str(int(roll_price))

func roll() -> void:
	item_stock.clear()
	for i in range(ITEM_AMOUNT):
		var item = items.keys().pick_random()
		item_stock.append(item)
		
		var button = get_node("Items/Item" + str(i + 1)) as TextureButton
		button.texture_normal = sprites[item]
		button.visible = true
		
		button.set_meta("item", item)
		button.mouse_entered.connect(func (): on_hover(button); show_description(item))
		button.mouse_exited.connect(func (): off_hover(button); hide_description(item))
		
		get_node("Items/Item" + str(i + 1) + "/UpgradeItem").visible = GameManager.player.owned_items.has(item)

func buy(button_idx: int) -> void:
	var button = get_node("Items/Item" + str(button_idx)) as TextureButton
	var item = button.get_meta("item")
	if !GameManager.can_afford(items[item].cost, Enums.Mineral.GOLD):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -items[item].cost)
	
	if GameManager.player.owned_items.has(item):
		GameManager.player.owned_items[item].upgrade()
		items[item].upgrade()
	else:
		GameManager.player.owned_items[item] = GameManager.player.all_items[item]
		GameManager.player.equipped_items[item] = GameManager.player.all_items[item]

	button.visible = false

func on_hover(button: TextureButton) -> void:
	if button.has_meta("bought"): return
	button.material.set_shader_parameter("width", 1.0)

func off_hover(button: TextureButton) -> void:
	if button.has_meta("bought"): return
	button.material.set_shader_parameter("width", 0.0)

func show_description(item: String) -> void:
	$DescriptionPanel.visible = true
	$DescriptionText.visible = true
	$DescriptionText.text = items[item].get_description(GameManager.player.owned_items.has(item))
	$Price/Price.text = items[item].get_cost()
	
	price_tween = create_tween()
	price_tween.tween_property($Price, "position", PRICE_VIS, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
func hide_description(item: String) -> void:
	$DescriptionPanel.visible = false
	$DescriptionText.visible = false
	
	price_tween = create_tween()
	price_tween.tween_property($Price, "position", PRICE_HIDDEN, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
