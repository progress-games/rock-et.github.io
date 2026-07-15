extends Node2D

const SWING_STRENGTH := 30
const PRICE_VIS := Vector2(122, 71)
const PRICE_HIDDEN := Vector2(122, 120)
const BASE_ROLL := 3

var sprites: Dictionary
var roll_price: float

@onready var potions: Array[TextureButton] = [
	$Stall/Potions/Potion1,
	$Stall/Potions/Potion2
]
@onready var items: Array[TextureButton] = [
	$Stall/Items/Item1,
	$Stall/Items/Item2,
	$Stall/Items/Item3
]
@onready var upgrade_item: Array[Sprite2D] = [
	$Stall/Items/Item1/UpgradeItem,
	$Stall/Items/Item2/UpgradeItem,
	$Stall/Items/Item3/UpgradeItem
]

@onready var item_capacity: TextureButton = $Stall/Capacity/ItemCapacity
@onready var potion_capacity: TextureButton = $Stall/Capacity/PotionCapacity

@onready var capacity: TextureRect = $Stall/Capacity
@onready var potion_holder: TextureRect = $Stall/Potions

var update_string: bool = false

func _ready() -> void:
	for n in GameManager.player.all_items.keys():
		sprites[n] = load("res://merchant/items/" + n + ".png")
	
	$RollButton.visible = false
	roll()
	
	$RollButton.mouse_entered.connect(func (): on_hover($RollButton))
	$RollButton.mouse_exited.connect(func (): off_hover($RollButton))
	GameManager.day_changed.connect(func (_x): 
		roll_price = BASE_ROLL; 
		$RollButton/Align/Price.text = str(int(roll_price))
		roll()
	)
	hide_description()
	
	var s = StatManager.get_stat("item_capacity")
	item_capacity.mouse_entered.connect(func (): on_hover(item_capacity); show_description(s.tooltip, s.cost))
	item_capacity.mouse_exited.connect(func (): off_hover(item_capacity); hide_description())
	
	s = StatManager.get_stat("potion_capacity")
	potion_capacity.mouse_entered.connect(func (): on_hover(potion_capacity); show_description(s.tooltip, s.cost))
	potion_capacity.mouse_exited.connect(func (): off_hover(potion_capacity); hide_description())
	
	GameManager.state_changed.connect(func (a): if a == Enums.State.MERCHANT: drop_stuff())

func buy_capacity(t: String) -> void:
	var stat = StatManager.get_stat(t + "_capacity")
	if !StatManager.can_upgrade_stat(t + "_capacity"):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -stat.cost)
	StatManager.upgrade_stat(t + "_capacity")
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	show_description(stat.tooltip, stat.cost)
	
	if stat.level == stat.max_level:
		if t == "item":
			item_capacity.disabled = true
			delete_all_signal_connections(item_capacity, "mouse_entered")
		else:
			potion_capacity.disabled = true
			delete_all_signal_connections(potion_capacity, "mouse_entered")

func pay_for_roll() -> void:
	if GameManager.can_afford(roll_price, Enums.Mineral.GOLD):
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ROLL)
		GameManager.add_mineral.emit(Enums.Mineral.GOLD, -roll_price)
		roll_price *= 1.5
		$RollButton/Align/Price.text = str(int(roll_price))
		roll()

func delete_all_signal_connections(obj: Object, signal_name: String):
	var sig = obj.get_signal_connection_list(signal_name)
	for c in sig:
		obj.disconnect(signal_name, c.callable)

func roll() -> void:
	for i in range(items.size()):
		var item = items[i]
		var item_type = GameManager.player.all_items.values().pick_random()
		
		item.texture_normal = sprites[item_type.name]
		item.visible = true
		
		delete_all_signal_connections(item, "mouse_entered")
		delete_all_signal_connections(item, "mouse_exited")
		
		set_item_meta(item, item_type.name)
		item.mouse_entered.connect(func (): on_hover(item); show_description(
			item_type.get_description(GameManager.player.owned_items.has(item_type.name)), item_type.cost))
		item.mouse_exited.connect(func (): off_hover(item); hide_description())
		
		upgrade_item[i].visible = GameManager.player.owned_items.has(item_type.name)
		upgrade_item[i].set_meta("item", item_type.name)
	
	for i in range(potions.size()):
		var potion = potions[i]
		var potion_type = GameManager.player.all_potions.values().pick_random() as Potion
		
		potion.texture_normal = potion_type.texture
		potion.visible = true
		
		var b = BitMap.new()
		b.create_from_image_alpha(potion_type.texture.get_image(), 0.5)
		potion.texture_click_mask = b
		potion.rotation_degrees = -10 if i == 0 else 10
		
		delete_all_signal_connections(potion, "mouse_entered")
		delete_all_signal_connections(potion, "mouse_exited")
		
		potion.set_meta("potion", potion_type)
		potion.mouse_entered.connect(func (): on_hover(potion); show_description(
			potion_type.potion_name.replace("_", " ") + ": " + potion_type.description, potion_type.cost))
		potion.mouse_exited.connect(func (): off_hover(potion); hide_description())

func buy_potion(button_idx: int) -> void:
	var button = potions[button_idx]
	var potion = button.get_meta("potion") as Potion
	if !GameManager.can_afford(potion.cost, Enums.Mineral.GOLD):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -potion.cost)
	
	GameManager.player.owned_potions.append(potion.potion_name)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	button.visible = false

func buy_item(button_idx: int) -> void:
	var button = items[button_idx] as TextureButton
	var item = button.get_meta("item")
	if !GameManager.can_afford(item.cost, Enums.Mineral.GOLD):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -item.cost)
	
	if GameManager.player.owned_items.has(item.name):
		GameManager.player.owned_items[item.name].upgrade()
	else:
		GameManager.player.owned_items[item.name] = GameManager.player.all_items[item.name]
		# GameManager.player.equipped_items[item] = GameManager.player.all_items[item]
	
	items.map(func (x): set_item_meta(x, x.get_meta("item").name))
	upgrade_item.map(func (x): x.visible = x.visible || x.get_meta("item") == item.name)
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	button.visible = false

# checks if we alr own the item and if so sets the meta to be the owned version
func set_item_meta(button: TextureButton, item_name: String) -> void:
	button.set_meta("item", GameManager.player.owned_items.get(item_name, GameManager.player.all_items[item_name]))

func on_hover(button: TextureButton) -> void:
	if button.has_meta("bought"): return
	button.material.set_shader_parameter("width", 1.0)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(button: TextureButton) -> void:
	if button.has_meta("bought"): return
	button.material.set_shader_parameter("width", 0.0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func show_description(description: String, price: int) -> void:
	$DescriptionPanel.visible = true
	$DescriptionText.visible = true
	$DescriptionText.text = description
	$Price/Price.text = str(price)
	
	var t = create_tween()
	t.tween_property($Price, "position", PRICE_VIS, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
func hide_description() -> void:
	$DescriptionPanel.hide()
	$DescriptionText.hide()
	
	var t = create_tween()
	t.tween_property($Price, "position", PRICE_HIDDEN, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)

func drop_stuff() -> void:
	var p_s = create_tween() # potion swing
	var c_s = create_tween()
	
	p_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	c_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var angle = SWING_STRENGTH
	p_s.tween_property(potion_holder, "rotation_degrees", angle, 0.2)
	p_s.tween_property(potion_holder, "rotation_degrees", -angle * 0.5 , 0.2)
	p_s.tween_property(potion_holder, "rotation_degrees", angle * 0.25, 0.2)
	p_s.tween_property(potion_holder, "rotation_degrees", 0, 0.2)
	
	angle = -SWING_STRENGTH * 0.75
	c_s.tween_property(capacity, "rotation_degrees", angle, 0.2)
	c_s.tween_property(capacity, "rotation_degrees", -angle * 0.5 , 0.2)
	c_s.tween_property(capacity, "rotation_degrees", angle * 0.25, 0.2)
	c_s.tween_property(capacity, "rotation_degrees", 0, 0.2)
