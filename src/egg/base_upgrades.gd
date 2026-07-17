extends Control

enum Tab {
	FREEZE,
	SHARD
}

const ON_HOVER_POS := 14
const OFF_HOVER_POS := 86
const PRICE_TWEEN_DUR := 0.3

const SELECTED_COLOUR := Color(0.18, 0.133, 0.184, 1.0)
const UNSELECTED_COLOUR := Color(0.282, 0.29, 0.467, 1.0)

@onready var price: NinePatchRect = $Price
@onready var price_text: Label = $Price/Price

@onready var freeze_chance: UpgradeButton = $Wall/Freeze/FreezeChance
@onready var hit_size: UpgradeButton = $Wall/Freeze/HitSize
@onready var freeze_dur: UpgradeButton = $Wall/Freeze/FreezeDur

@onready var shard_amount: UpgradeButton = $Wall/Shard/ShardAmount
@onready var shard_chance: UpgradeButton = $Wall/Shard/ShardChance
@onready var shard_damage: UpgradeButton = $Wall/Shard/ShardPierce

@onready var freeze_buttons: Control = $Wall/Freeze
@onready var shard_buttons: Control = $Wall/Shard

@onready var freeze_stats: Control = $Stats/Freeze
@onready var shard_stats: Control = $Stats/Shard

@onready var freeze_tab: TextureButton = $Tabs/FreezeTab
@onready var locked_tab: TextureButton = $Tabs/LockedTab
@onready var shard_tab: TextureButton = $Tabs/ShardTab

var current_tab: Tab = Tab.FREEZE

func _ready() -> void:
	#GameManager.add_mineral.emit(Enums.Mineral.LARIMAR, 1000)
	freeze_chance.mouse_entered.connect(func (): show_price("freeze_chance"))
	freeze_chance.mouse_exited.connect(hide_price)
	
	hit_size.mouse_entered.connect(func (): show_price("kruos_hit_size"))
	hit_size.mouse_exited.connect(hide_price)
	
	freeze_dur.mouse_entered.connect(func (): show_price("freeze_duration"))
	freeze_dur.mouse_exited.connect(hide_price)
	
	shard_amount.mouse_entered.connect(func (): show_price("shard_amount"))
	shard_amount.mouse_exited.connect(hide_price)
	
	shard_chance.mouse_entered.connect(func (): show_price("shard_chance"))
	shard_chance.mouse_exited.connect(hide_price)
	
	shard_damage.mouse_entered.connect(func (): show_price("shard_pierce"))
	shard_damage.mouse_exited.connect(hide_price)
	
	freeze_tab.mouse_entered.connect(func (): freeze_tab.material.set_shader_parameter("width", 1); on_hover())
	freeze_tab.mouse_exited.connect(func (): freeze_tab.material.set_shader_parameter("width", 0); off_hover())
	freeze_tab.pressed.connect(func (): set_tab(Tab.FREEZE))
	
	locked_tab.mouse_entered.connect(func (): 
		locked_tab.material.set_shader_parameter("width", 1)
		show_price("shard_ability"))
	locked_tab.mouse_exited.connect(func (): 
		locked_tab.material.set_shader_parameter("width", 0)
		hide_price())
	locked_tab.pressed.connect(func ():
		if StatManager.can_upgrade_stat("shard_ability"):
			StatManager.upgrade_stat("shard_ability")
			GameManager.add_mineral.emit(Enums.Mineral.LARIMAR, StatManager.get_stat("shard_ability").value)
			set_tab(Tab.SHARD))
	
	shard_tab.mouse_entered.connect(func (): shard_tab.material.set_shader_parameter("width", 1); on_hover())
	shard_tab.mouse_exited.connect(func (): shard_tab.material.set_shader_parameter("width", 0); off_hover())
	shard_tab.pressed.connect(func (): set_tab(Tab.SHARD))
	
	StatManager.stat_upgraded.connect(
		func (s: Stat):
			price_text.text = s.display_cost
			if s.stat_name == "shard_ability":
				locked_tab.visible = false
				shard_tab.visible = true
	)
	
	set_tab(Tab.FREEZE)
	hide_price()

func set_tab(tab: Tab) -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	current_tab = tab
	
	freeze_buttons.visible = tab == Tab.FREEZE
	shard_buttons.visible = tab == Tab.SHARD
	freeze_stats.visible = tab == Tab.FREEZE
	shard_stats.visible = tab == Tab.SHARD
	
	freeze_tab.material.set_shader_parameter("replacement_colors", [SELECTED_COLOUR if tab == Tab.FREEZE else UNSELECTED_COLOUR])
	shard_tab.material.set_shader_parameter("replacement_colors", [SELECTED_COLOUR if tab == Tab.SHARD else UNSELECTED_COLOUR])
	

func on_hover() -> void:
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)

func off_hover() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)

func show_price(u: String) -> void:
	price_text.text = StatManager.get_stat(u).display_cost
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	
	var t = create_tween()
	t.tween_property(price, "position:x", ON_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_price() -> void:
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	var t = create_tween()
	t.tween_property(price, "position:x", OFF_HOVER_POS, PRICE_TWEEN_DUR).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
