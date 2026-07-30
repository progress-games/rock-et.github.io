extends Node2D

const SWING_STRENGTH := 30
const PRICE_VIS := Vector2(122, 71)
const PRICE_HIDDEN := Vector2(122, 120)
const BASE_ROLL := 3

const DESC_HIDDEN := 190
const DESC_VIS := 144

const LEVEL_NUMERALS := [
	preload("uid://cd1tqwabaxwv"),
	preload("uid://cs15r4nr7fjdy"),
	preload("uid://vc7n05ygstwg"),
	preload("uid://r2oc74egnjd"),
	preload("uid://c3bpgel8yhwft"),
	preload("uid://cee2g7qgqk6tx")
]

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

@onready var item_amount: Array[Label] = [
	$Stall/Items/Item1/Amount,
	$Stall/Items/Item2/Amount,
	$Stall/Items/Item3/Amount
]

@onready var item_duplicate: Array[TextureRect] = [
	$Stall/Items/Item1/Duplicates,
	$Stall/Items/Item2/Duplicates,
	$Stall/Items/Item3/Duplicates
]

@onready var description_panel: NinePatchRect = $DescriptionPanel
@onready var description_text: RichTextLabel = $DescriptionPanel/DescriptionText

@onready var roll_button: TextureButton = $RollButton

@onready var item_capacity: TextureButton = $Stall/Capacity/ItemCapacity
@onready var potion_capacity: TextureButton = $Stall/Capacity/PotionCapacity

@onready var capacity: TextureRect = $Stall/Capacity
@onready var potion_holder: TextureRect = $Stall/Potions

@onready var level_up: TextureButton = $Stall/Stall/LevelUp
@onready var current_level: TextureRect = $Stall/Stall/CurrentLevel
@onready var stall_level: TextureRect = $Stall/Stall

var group_items: bool = false

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.GOLD, 1000)
	for n in GameManager.player.all_items.keys():
		sprites[n] = load("res://merchant/items/" + n + ".png")
	
	roll_button.visible = false
	roll()
	
	roll_button.mouse_entered.connect(func (): on_hover(roll_button))
	roll_button.mouse_exited.connect(func (): off_hover(roll_button))
	roll_button.pressed.connect(func ():
		roll()
		roll_button.disabled = true
		roll_button.modulate = Color(0, 0, 0, 0.3))
	GameManager.day_changed.connect(func (_x):
		roll_button.modulate = Color(1, 1, 1)
		roll_button.disabled = false
		roll()
	)
	hide_description()
	
	var s = StatManager.get_stat("item_capacity")
	item_capacity.mouse_entered.connect(func (): on_hover(item_capacity); show_description(s.tooltip, s.cost))
	item_capacity.mouse_exited.connect(func (): off_hover(item_capacity); hide_description())
	item_capacity.pressed.connect(func (): buy_stat("item_capacity", item_capacity))
	
	s = StatManager.get_stat("potion_capacity")
	potion_capacity.mouse_entered.connect(func (): on_hover(potion_capacity); show_description(s.tooltip, s.cost))
	potion_capacity.mouse_exited.connect(func (): off_hover(potion_capacity); hide_description())
	potion_capacity.pressed.connect(func (): buy_stat("potion_capacity", potion_capacity))
	
	s = StatManager.get_stat("stall_level")
	level_up.mouse_entered.connect(func (): on_hover(level_up); show_description(StatManager.get_stall_current_desc(), s.cost))
	level_up.mouse_exited.connect(func (): off_hover(level_up); hide_description())
	level_up.pressed.connect(func (): buy_stat("stall_level", level_up))
	
	s.upgraded.connect(level_upgraded)
	
	GameManager.state_changed.connect(func (a): if a == Enums.State.MERCHANT: drop_stuff())

func level_upgraded() -> void:
	var s = StatManager.get_stat("stall_level")
	current_level.texture = LEVEL_NUMERALS[s.level - 1]
	hide_description()
	show_description(StatManager.get_stall_current_desc(), s.cost)
	
	match s.level:
		2:
			potion_holder.visible = true
		3:
			capacity.visible = true
		5:
			roll_button.visible = true
		6:
			group_items = true

func buy_stat(t: String, b: TextureButton) -> void:
	var stat = StatManager.get_stat(t)
	if !StatManager.can_upgrade_stat(t):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -stat.cost)
	StatManager.upgrade_stat(t)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	
	
	if stat.level == stat.max_level:
		b.disabled = true
		delete_all_signal_connections(b, "mouse_entered")
		b.mouse_entered.connect(func (): on_hover(b); show_description("max level!", 0))
	
	b.mouse_entered.emit()

func delete_all_signal_connections(obj: Object, signal_name: String):
	var sig = obj.get_signal_connection_list(signal_name)
	for c in sig:
		obj.disconnect(signal_name, c.callable)

func roll() -> void:
	for i in range(items.size()):
		var item = items[i]
		var item_type = GameManager.player.all_items\
			.values()\
			.filter(func (x): 
				return x.name != "mad_scientist" || StatManager.get_stat("stall_level").level > 2)\
			.pick_random()
		
		item.texture_normal = sprites[item_type.name]
		item.visible = true
		
		delete_all_signal_connections(item, "mouse_entered")
		delete_all_signal_connections(item, "mouse_exited")
		
		var amount = 1
		if group_items:
			amount = [1, 1, 2, 2, 3, 4, 5].pick_random()
		
		item_amount[i].visible = amount > 1
		item_duplicate[i].visible = amount > 1
		if amount > 1:
			item_duplicate[i].texture = sprites[item_type.name]
			item_amount[i].text = "x" + str(amount)
		
		item.set_meta("amount", amount)
		set_item_meta(item, item_type.name)
		item.mouse_entered.connect(func (): 
			on_hover(item)
			show_item_description(item_type.name, amount)
		)
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
		potion.mouse_entered.connect(func (): 
			on_hover(potion); 
			var mult = 1.
			if GameManager.player.owned_items.has("mad_scientist"):
				mult *= GameManager.player.owned_items.mad_scientist.values.potion_multiplier.value
			show_description(potion_type.get_description(mult), potion_type.cost))
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
	var item = button.get_meta("item") as Item
	var amount = button.get_meta('amount')
	var cost = item.get_cost(amount)
	
	if !GameManager.can_afford(cost, Enums.Mineral.GOLD):
		return
	
	GameManager.add_mineral.emit(Enums.Mineral.GOLD, -cost)
	
	var new_particles = ParticleManager.get_particles(ParticleManager.ParticleType.SPENT_COINS)
	new_particles.emitting = true
	new_particles.position = button.position + Vector2(16, 16)
	add_child(new_particles)
	
	for i in range(amount):
		if GameManager.player.owned_items.has(item.name):
			GameManager.player.owned_items[item.name].upgrade()
		else:
			GameManager.player.owned_items[item.name] = GameManager.player.all_items[item.name]
			GameManager.player.owned_items[item.name].update_cost()
		# GameManager.player.equipped_items[item] = GameManager.player.all_items[item]
	
	items.map(func (x): set_item_meta(x, x.get_meta("item").name))
	upgrade_item.map(func (x): x.visible = x.visible || x.get_meta("item") == item.name)
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	button.visible = false

func show_item_description(item_name: String, amount: int = 1) -> void:
	var item = GameManager.player.all_items[item_name]
	var owned = GameManager.player.owned_items.has(item_name)
	show_description(item.get_description(owned, amount), item.get_cost(amount))

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
	description_text.text = description
	$Price/Price.text = str(price)
	
	var t = create_tween()
	t.tween_property($Price, "position", PRICE_VIS, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(description_panel, "position:y", DESC_VIS, 0.3)

func hide_description() -> void:
	var t = create_tween()
	t.tween_property($Price, "position", PRICE_HIDDEN, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	
	var t2 = create_tween()
	t2.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t2.tween_property(description_panel, "position:y", DESC_HIDDEN, 0.3)

func drop_stuff() -> void:
	var p_s = create_tween() # potion swing
	var c_s = create_tween() # capacity swing
	var l_s = create_tween() # level swing
	
	p_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	c_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	l_s.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
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
	
	l_s.tween_property(stall_level, "rotation_degrees", angle, 0.2)
	l_s.tween_property(stall_level, "rotation_degrees", -angle * 0.5 , 0.2)
	l_s.tween_property(stall_level, "rotation_degrees", angle * 0.25, 0.2)
	l_s.tween_property(stall_level, "rotation_degrees", 0, 0.2)
