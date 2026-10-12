extends Control

@onready var tree: Control = $NinePatchRect/SubViewportContainer/SubViewport/StonehouseSkillTree
@onready var description: RichTextLabel = $VBoxContainer/MarginContainer/MarginContainer2/Description
@onready var buying: HBoxContainer = $VBoxContainer/Buying

@onready var buy: TextureButton = $VBoxContainer/Buying/Buy
@onready var price: Label = $VBoxContainer/Buying/MarginContainer2/MarginContainer2/HBoxContainer/Price

var selected_node: StonehouseNode

func _ready() -> void:
	tree.node_selected.connect(update_description)
	
	buy.mouse_entered.connect(
		func ():
			buy.material.set_shader_parameter("width", 1)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	)
	
	buy.mouse_exited.connect(
		func ():
			buy.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	)
	
	buy.pressed.connect(buy_selected)
	
	update_description(tree.root)

func buy_selected() -> void:
	#if !GameManager.can_afford(int(ceil(selected_node.price)), Enums.Mineral.BIOTITE):
		#AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE)
		#return
	
	selected_node.unlock()
	GameManager.add_mineral.emit(Enums.Mineral.BIOTITE, -selected_node.price)
	update_description(selected_node)

func update_description(node: StonehouseNode) -> void:
	selected_node = node
	
	description.text = BounceEffectManager.get_description(
		selected_node.effect_type,
		selected_node.stat_type,
		selected_node.amount
	)
	
	if node.unlocked:
		description.text += "[br][br][color=#FFFFFF49][i]UNLOCKED[/i]"
		buying.hide()
		return
	
	if node.dependencies.any(func (x): return !x.unlocked):
		description.text += "[br][br][color=#FFFFFF49][i]LOCKED[/i]"
		buying.hide()
		return
	
	buying.show()
	price.text = str(int(ceil(node.price)))
