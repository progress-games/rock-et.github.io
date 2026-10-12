extends Control

const UPGRADE_STAT = preload("uid://6exf7bj3j40b")
const UNLOCK_STAT = preload("uid://by3cbf5kmt51s")
const HOVER_UNLOCK_STAT = preload("uid://c3xw1sugf7nlr")

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const UPGRADE_ORDER := [
	"pickaxe_durability",
	"scavenge_rarity",
	"scavenge_grid",
	"pickaxe_damage",
	"merge_slots",
	"daily_scavenges"
]

const UPGRADE_SPRITES = {
	"pickaxe_durability": preload("uid://k66wlc3pavc5"),
	"merge_slots": preload("uid://duqpmhjg1qsqw"),
	"scavenge_rarity": preload("uid://th77wtjcfe72"),
	"pickaxe_damage": preload("uid://ctq21c2nnc4q5"),
	"scavenge_grid": preload("uid://jlqtdfj24w6m"),
	"daily_scavenges": preload("uid://xmwidcut830e")
}

@onready var next_upgrade_button: TextureButton = $Upgrades/MarginContainer/MarginContainer2/HBoxContainer/TextureButton7

@onready var upgrade_tab: HBoxContainer = $Upgrades/MarginContainer/MarginContainer2/HBoxContainer
@onready var upgrades_vbox: VBoxContainer = $Upgrades

@onready var price: TextureRect = $Price
@onready var price_text: Label = $Price/Price

@onready var stat_name_label: Label = $Upgrades/MarginContainer2/MarginContainer2/Label

@onready var upgrade_button: UpgradeButton = $Upgrades/HBoxContainer/UpgradeButton

@onready var stat_display: RichTextLabel = $Upgrades/HBoxContainer/MarginContainer/MarginContainer2/StatDisplay
@onready var stat_display_hover: RichTextLabel = $Upgrades/HBoxContainer/MarginContainer/MarginContainer2/StatDisplayHover

var price_tween: Tween

func _ready() -> void:
	setup_buttons()
	setup_next_upgrade_button()
	
	select_stat(UPGRADE_ORDER[0])
	
	hide_price()
	
	upgrade_button.mouse_entered.connect(func (): show_price(upgrade_button))
	upgrade_button.mouse_exited.connect(func (): hide_price())
	upgrade_button.pressed.connect(func (): 
		update_stat_display(upgrade_button.stat_name)
		show_price(upgrade_button))
	
	StatManager.get_stat("floatie_level").upgraded.connect(refresh_buttons)
	StatManager.stat_upgraded.connect(
		func (s: Stat):
			if s.stat_name in UPGRADE_ORDER:
				select_stat(s.stat_name)
	)

func setup_buttons() -> void:
	var shader = ShaderMaterial.new()
	shader.shader = WHITE_OUTLINE
	
	for i in range(UPGRADE_ORDER.size()):
		var button = upgrade_tab.get_child(i)
		button.visible = i < StatManager.get_stat("floatie_level").level
		button.texture_normal = UPGRADE_SPRITES[UPGRADE_ORDER[i]]
		button.material = shader.duplicate()
		button.material.set_shader_parameter("width", 0)
		
		button.mouse_entered.connect(func (): hover(button))
		button.mouse_exited.connect(func (): off_hover(button))
		button.pressed.connect(func (): select_stat(UPGRADE_ORDER[i]))

func refresh_buttons() -> void:
	for i in range(UPGRADE_ORDER.size()):
		var button = upgrade_tab.get_child(i)
		button.visible = i < StatManager.get_stat("floatie_level").level
	
	next_upgrade_button.visible = StatManager.get_stat("floatie_level").level < \
		StatManager.get_stat("floatie_level").max_level
	
	select_stat(UPGRADE_ORDER[StatManager.get_stat("floatie_level").level - 1])

func hover(b) -> void:
	b.material.set_shader_parameter("width", 1)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b) -> void:
	b.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func pop_stat() -> void:
	upgrades_vbox.scale = Vector2.ONE * 1.2
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(upgrades_vbox, "scale", Vector2.ONE, 0.2)

func setup_next_upgrade_button() -> void:
	next_upgrade_button.mouse_entered.connect(func (): hover(next_upgrade_button))
	next_upgrade_button.mouse_exited.connect(func (): off_hover(next_upgrade_button))
	next_upgrade_button.pressed.connect(select_unknown_stat)

func update_stat_display(stat_name: String) -> void:
	stat_display_hover.text = StatManager.get_stat(stat_name).display_value +\
		"[color=#4d9be6ff] [img color=#4d9be6ff]res://common/ui/upgrades/upgrade_arrow.png[/img] " + \
		StatManager.get_stat(stat_name).next_level.display_value
	stat_display_hover.modulate = Color.TRANSPARENT
	
	stat_display.text = StatManager.get_stat(stat_name).display_value

func select_stat(stat_name: String) -> void:
	pop_stat()
	upgrade_button.change_stat(stat_name)
	update_stat_display(stat_name)
	stat_name_label.text = stat_name.replace("_", " ")
	upgrade_button.texture_normal = UPGRADE_STAT
	upgrade_button.texture_hover = null

func select_unknown_stat() -> void:
	pop_stat()
	upgrade_button.change_stat("floatie_level")
	upgrade_button.texture_normal = UNLOCK_STAT
	upgrade_button.texture_hover = HOVER_UNLOCK_STAT
	
	stat_name_label.text = "???"
	stat_display.text = "???"
	stat_display_hover.text = "???"

func show_price(button: UpgradeButton) -> void:
	price_text.text = StatManager.get_stat(button.stat_name).display_cost
	
	price.scale = Vector2.ZERO
	
	if stat_display.text != "???":
		stat_display_hover.modulate = Color.WHITE
		stat_display.hide()
	
	if price_tween != null: price_tween.kill()
	
	price_tween = create_tween()
	price_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	price_tween.tween_property(price, "scale", Vector2.ONE, 0.3)

func hide_price() -> void:
	if price_tween != null: price_tween.kill()
	
	stat_display_hover.modulate = Color.TRANSPARENT
	stat_display.show()
	
	price_tween = create_tween()
	price_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	price_tween.tween_property(price, "scale", Vector2.ZERO, 0.3)
