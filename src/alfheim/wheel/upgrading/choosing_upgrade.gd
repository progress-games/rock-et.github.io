extends Control
class_name WheelUpgradeChoice

enum UpgradeStrength {
	LOW,
	MED,
	HIGH,
	FINAL
}

const WHITE_OUTLINE = preload("uid://dstl4edni51y1")
const DESC_OFF_HOVER := 191
const DESC_ON_HOVER := 155
const BAR_WIDTH := 50

"""
stats:
daily spins
bar discount
loss chance
bar reroll
loss subtraction
win width
legendary chance multiplier
wheel reroll
common effect mult



LOW:
+1 daily spin
new common reward: +10 diamonds
new uncommon reward: +20 diamonds
new rare reward: +100 diamonds | new uncommon loss: -20 diamonds
losses are 10% less common
15% bar discount
new common reward: +15 diamonds | new common loss: -10 diamonds
new legendary reward: +500 diamonds
new uncommon reward: +50 diamonds | new rare loss: -150 diamonds

MED
all losses are 5 diamonds less
+1 daily spin
+1 bar reroll
new common reward: +20 diamonds | new legendary loss: -999 diamonds
remove: common reward +5 diamonds
remove: common loss -5 diamonds
win portions are 10% wider
new uncommon reward: +2 spins
legendary wins & losses are 2x more common

HIGH
+2 daily spins
new common reward: 2 spins | new uncommon loss: -10 diamonds
new legendary reward: +999 diamonds | new rare loss: -300 diamonds
remove the lowest common reward
remove the lowest common loss
losses are 10% less common

FINAL:
legendary wins & losses are 4x more common
you may reroll the wheel once a day
all common win and loss effects are doubled"""

var upgrades: Dictionary[UpgradeStrength, Array] = {
	UpgradeStrength.LOW: [
		WheelUpgrade.new({
			"short_desc": "keep spinning [img]res://alfheim/wheel/spin_ticket.png[/img]",
			"long_desc": "+2 daily spins",
			"upgrade_func": func (): set_stat("daily_spins", 2)
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 10,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.COMMON
			}
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 20,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.UNCOMMON
			}
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 50,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.RARE
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 10,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.UNCOMMON
			}
		}),
		WheelUpgrade.new({
			"short_desc": "lose less [img]res://alfheim/wheel/upgrading/icons/lose less.png[/img]",
			"long_desc": "losses are 10% less common",
			"upgrade_func": func (): set_stat("loss_chance", .1)
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 20,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.COMMON
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 10,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.COMMON
			}
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 199,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.ULTRA_RARE
			}
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 30,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.UNCOMMON
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 150,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.RARE
			}
		}),
	],
	UpgradeStrength.MED: [
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 40,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.UNCOMMON
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 299,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.ULTRA_RARE
			}
		}),
		WheelUpgrade.new({
			"short_desc": "better losses [img]res://alfheim/wheel/upgrading/icons/better losses.png[/img]",
			"long_desc": "all losses are 5 [img]res://common/minerals/diamond.png[/img] less",
			"upgrade_func": func (): set_stat("loss_subtraction", 5)
		}),
		WheelUpgrade.new({
			"short_desc": "keep spinning [img]res://alfheim/wheel/spin_ticket.png[/img]",
			"long_desc": "+2 daily spins",
			"upgrade_func": func (): set_stat("daily_spins", 2)
		}),
		WheelUpgrade.new({
			"short_desc": "another round [img]res://alfheim/wheel/upgrading/icons/another round.png[/img]",
			"long_desc": "+1 daily bar reroll",
			"upgrade_func": func (): set_stat("bar_reroll", 1)
		}),
		WheelUpgrade.new({
			"short_desc": "refined [img]res://alfheim/wheel/upgrading/icons/refined.png[/img]",
			"long_desc": "remove the highest value common loss",
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 25,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.COMMON
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 15,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.COMMON
			}
		}),
		WheelUpgrade.new({
			"short_desc": "wider wins [img]res://alfheim/wheel/upgrading/icons/wider wins.png[/img]",
			"long_desc": "win portions are 20% wider",
			"upgrade_func": func (): set_stat("win_width", .2)
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.SPINS,
				"amount": 2,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.UNCOMMON
			}
		}),
		WheelUpgrade.new({
			"short_desc": "you feel lucky [img]res://alfheim/wheel/upgrading/icons/lucky.png[/img]",
			"long_desc": "ultra rare wins and losses are 2x more common",
			"upgrade_func": func (): set_stat("ultra_rare_chance", 2, true)
		}),
		WheelUpgrade.new({
			"short_desc": "become a regular [img]res://alfheim/wheel/upgrading/icons/regular.png[/img]",
			"long_desc": "15% bar discount",
			"upgrade_func": func (): set_stat("bar_discount", .15)
		}),
	],
	UpgradeStrength.HIGH: [
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.SPINS,
				"amount": 2,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.COMMON
			},
			"portion_2": {
				"reward": WheelPortion.Reward.SPINS,
				"amount": 3,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.UNCOMMON
			}
		}),
		WheelUpgrade.new({
			"short_desc": "keep spinning [img]res://alfheim/wheel/spin_ticket.png[/img]",
			"long_desc": "+3 daily spins",
			"upgrade_func": func (): set_stat("daily_spins", 3)
		}),
		WheelUpgrade.new({
			"portion_1": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 399,
				"outcome": WheelPortion.Outcome.WIN,
				"rarity": WheelPortion.Rarity.ULTRA_RARE
			},
			"portion_2": {
				"reward": WheelPortion.Reward.DIAMONDS,
				"amount": 300,
				"outcome": WheelPortion.Outcome.LOSS,
				"rarity": WheelPortion.Rarity.RARE
			}
		}),
		WheelUpgrade.new({
			"short_desc": "refined [img]res://alfheim/wheel/upgrading/icons/refined.png[/img]",
			"long_desc": "remove the highest value common loss"
		}),
		WheelUpgrade.new({
			"short_desc": "lose less [img]res://alfheim/wheel/upgrading/icons/lose less.png[/img]",
			"long_desc": "losses are 10% less common",
			"upgrade_func": func (): set_stat("loss_chance", .1)
		}),
	],
	UpgradeStrength.FINAL: [
		WheelUpgrade.new({
			"short_desc": "golden luck [img]res://alfheim/wheel/upgrading/icons/goldenluck.png[/img]",
			"long_desc": "ultra rare wins and losses are 4x more common",
			"upgrade_func": func (): set_stat("ultra_rare_chance", 4, true)
		}),
		WheelUpgrade.new({
			"short_desc": "gamble fate [img]res://alfheim/wheel/upgrading/icons/gamble with fate.png[/img]",
			"long_desc": "you may reroll the wheel 3x a day",
			"upgrade_func": func (): set_stat("wheel_reroll", 3)
		}),
		WheelUpgrade.new({
			"short_desc": "powerful commons [img]res://alfheim/wheel/upgrading/icons/powerful commons.png[/img]",
			"long_desc": "all common win and loss effects are doubled",
			"upgrade_func": func (): set_stat("common_multiplier", 1)
		}),
	]
}

@export var outcome_colours: Dictionary[WheelPortion.Outcome, Color]
@export var win_colours: Dictionary[WheelPortion.Rarity, WheelColour]
@export var loss_colours: Dictionary[WheelPortion.Rarity, WheelColour]

@export var upgrade_buttons: Array[WheelUpgradeButton]

@onready var description: HBoxContainer = $Description
@onready var description_label: RichTextLabel = $Description/MarginContainer/MarginContainer2/Label
@onready var wheel_level: UpgradeButton = $Upgrade/WheelLevel

@onready var choices_panel: VBoxContainer = $Choices
@onready var upgrade_panel: VBoxContainer = $Upgrade
@onready var level_descriptions: Array[TextureButton] = [
	$"Upgrade/Levels/1", 
	$"Upgrade/Levels/2", 
	$"Upgrade/Levels/3", 
	$"Upgrade/Levels/4", 
	$"Upgrade/Levels/5", 
	$"Upgrade/Levels/6", 
	$"Upgrade/Levels/7", 
	$"Upgrade/Levels/8", 
	$"Upgrade/Levels/9", 
	$"Upgrade/Levels/10"
]

@onready var outcome_rects: Dictionary[WheelPortion.Outcome, ColorRect] = {
	WheelPortion.Outcome.WIN: $Upgrade/Chances/MarginContainer/VBoxContainer/Outcomes/Outcomes/Win,
	WheelPortion.Outcome.LOSS: $Upgrade/Chances/MarginContainer/VBoxContainer/Outcomes/Outcomes/Loss
}

@onready var rarity_rects: Dictionary[WheelPortion.Rarity, ColorRect] = {
	WheelPortion.Rarity.COMMON: $Upgrade/Chances/MarginContainer/VBoxContainer/Rarities/Outcomes2/Common,
	WheelPortion.Rarity.UNCOMMON: $Upgrade/Chances/MarginContainer/VBoxContainer/Rarities/Outcomes2/Uncommon,
	WheelPortion.Rarity.RARE: $Upgrade/Chances/MarginContainer/VBoxContainer/Rarities/Outcomes2/Rare,
	WheelPortion.Rarity.ULTRA_RARE: $Upgrade/Chances/MarginContainer/VBoxContainer/Rarities/Outcomes2/UltraRare
}


var past_upgrades: Array[WheelUpgrade]

signal upgrade_chosen(upgrade: WheelUpgrade)

func _ready() -> void:
	for i in upgrade_buttons.size():
		var b = get_node(upgrade_buttons[i].button) as TextureButton
		b.mouse_entered.connect(func (): on_hover(i))
		b.mouse_exited.connect(func (): off_hover(i))
		b.pressed.connect(func (): choose_upgrade(i))
	
	choices_panel.hide()
	upgrade_panel.show()
	setup_level_desc()
	refresh_level_desc()
	setup_bars()
	
	StatManager.get_stat("wheel_level").upgraded.connect(show_choose_one)

func show_choose_one() -> void:
	generate_upgrade_choice()
	choices_panel.show()
	upgrade_panel.hide()

func refresh_level_desc() -> void:
	level_descriptions.map(
		func (b: TextureButton) -> void:
			b.modulate = Color(0, 0, 0, 0.4)
			b.get_child(0).visible = false
	)
	
	for i in past_upgrades.size():
		var past_upgrade = past_upgrades[i]
		level_descriptions[i].modulate = Color.WHITE
		level_descriptions[i].get_child(0).visible = true
		level_descriptions[i].set_meta("upgrade", past_upgrade)

func setup_level_desc() -> void:
	var white_outline = ShaderMaterial.new()
	white_outline.shader = WHITE_OUTLINE
	
	for i in level_descriptions.size():
		var b = level_descriptions[i]
		b.material = white_outline.duplicate()
		b.material.set_shader_parameter("width", 0)
		b.mouse_entered.connect(func (): 
			if !b.has_meta("upgrade"): return
			b.material.set_shader_parameter("width", 1)
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
			GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
			show_level_description(i))
		b.mouse_exited.connect(func ():
			if !b.has_meta("upgrade"): return
			b.material.set_shader_parameter("width", 0)
			GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
			hide_description())

func show_level_description(idx: int) -> void:
	if !level_descriptions[idx].has_meta("upgrade"):
		return
	var upgrade = level_descriptions[idx].get_meta("upgrade")
	show_description(upgrade.get_description())

func choose_upgrade(idx: int) -> void:
	var upgrade_button = upgrade_buttons[idx]
	var upgrade = get_node(upgrade_button.button).get_meta("upgrade")
	past_upgrades.append(upgrade)
	upgrade_chosen.emit(upgrade)
	choices_panel.hide()
	upgrade_panel.show()
	refresh_level_desc()

func get_current_strength() -> UpgradeStrength:
	var l = StatManager.get_stat("wheel_level").level
	if l <= 3: return UpgradeStrength.LOW
	if l <= 6: return UpgradeStrength.MED
	if l <= 10: return UpgradeStrength.HIGH
	return UpgradeStrength.FINAL

func generate_upgrade_choice() -> void:
	var strength = get_current_strength()
	
	var chosen: Array[WheelUpgrade] = []
	for button in upgrade_buttons:
		var upgrade = upgrades[strength].pick_random() as WheelUpgrade
		while upgrade in chosen:
			upgrade = upgrades[strength].pick_random() as WheelUpgrade
		chosen.append(upgrade)
		get_node(button.button).set_meta("upgrade", upgrade)
		get_node(button.description).visible = upgrade.short_desc != ""
		get_node(button.portion_1).visible = upgrade.new_portion_1 != null
		get_node(button.portion_2).visible = upgrade.new_portion_2 != null
		get_node(button.description).text = upgrade.short_desc
		
		if upgrade.new_portion_1 != null:
			var colour_dict = win_colours if upgrade.new_portion_1.outcome == WheelPortion.Outcome.WIN \
				else loss_colours
			
			get_node(button.portion_1_panel).material.set_shader_parameter(
				"replacement_colors", 
				[
					colour_dict[upgrade.new_portion_1.rarity].outline,
					colour_dict[upgrade.new_portion_1.rarity].shadow,
					colour_dict[upgrade.new_portion_1.rarity].mid,
					colour_dict[upgrade.new_portion_1.rarity].highlight
				])
			
			get_node(button.portion_1_description).text = upgrade.new_portion_1.reward_text
		
		if upgrade.new_portion_2 != null:
			var colour_dict = win_colours if upgrade.new_portion_2.outcome == WheelPortion.Outcome.WIN \
				else loss_colours
			
			get_node(button.portion_2_panel).material.set_shader_parameter(
				"replacement_colors", 
				[
					colour_dict[upgrade.new_portion_2.rarity].outline,
					colour_dict[upgrade.new_portion_2.rarity].shadow,
					colour_dict[upgrade.new_portion_2.rarity].mid,
					colour_dict[upgrade.new_portion_2.rarity].highlight
				])
			
			get_node(button.portion_2_description).text = upgrade.new_portion_2.reward_text

func on_hover(idx: int) -> void:
	var upgrade_button = get_node(upgrade_buttons[idx].button)
	upgrade_button.material.set_shader_parameter("width", 1)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	
	show_description(upgrade_button.get_meta("upgrade").get_description())

func off_hover(idx: int) -> void:
	var upgrade_button = get_node(upgrade_buttons[idx].button)
	upgrade_button.material.set_shader_parameter("width", 0)
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	
	hide_description()

func show_description(s: String) -> void:
	description_label.text = s
	
	var t = create_tween()
	t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(description, "position:y", DESC_ON_HOVER, 0.3)

func hide_description() -> void:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	t.tween_property(description, "position:y", DESC_OFF_HOVER, 0.3)

func set_stat(stat_name: String, amount: float, mult: bool = false) -> void:
	var s = StatManager.get_stat(stat_name)
	if mult: s.value *= amount
	else: s.value += amount
	s.level += 1

func update_outcome_desc(outcome: WheelPortion.Outcome, chances: Dictionary[WheelPortion.Outcome, float]) -> void:
	show_description(WheelPortion.Outcome.find_key(outcome).to_lower() + " chance: " + \
		str(int(ceil(chances[outcome] * 100))) + "%")

func update_rarity_desc(rarity: WheelPortion.Rarity, chances: Dictionary[WheelPortion.Rarity, float]) -> void:
	show_description(WheelPortion.Rarity.find_key(rarity).to_lower().replace("_", " ") + " chance: " + \
		str(int(ceil(chances[rarity] * 100))) + "%")

func setup_bars() -> void:
	for outcome in outcome_rects.keys():
		var rect = outcome_rects[outcome]
		rect.set_meta("outcome", outcome)
		rect.set_meta("chances", {})
		rect.mouse_entered.connect(func (): 
			rect.color = Color.WHITE
			update_outcome_desc(rect.get_meta("outcome"), rect.get_meta("chances")))
		rect.mouse_exited.connect(func (): 
			rect.color = outcome_colours[outcome]
			hide_description())
	
	for rarity in rarity_rects.keys():
		var rect = rarity_rects[rarity]
		rect.set_meta("rarity", rarity)
		rect.set_meta("chances", {})
		rect.mouse_entered.connect(func ():
			rect.color = Color.WHITE
			update_rarity_desc(rect.get_meta("rarity"), rect.get_meta("chances")))
		rect.mouse_exited.connect(func (): 
			rect.color = win_colours[rarity].mid
			hide_description())

func update_bars(outcome_chances: Dictionary[WheelPortion.Outcome, float],
	rarity_chances: Dictionary[WheelPortion.Rarity, float]) -> void:
	
	for outcome in outcome_chances.keys():
		outcome_rects[outcome].set_meta("chances", outcome_chances)
		outcome_rects[outcome].custom_minimum_size.x = floor(
			outcome_chances[outcome] * (BAR_WIDTH - 1))
	
	for rarity in rarity_chances.keys():
		rarity_rects[rarity].set_meta("chances", rarity_chances)
		rarity_rects[rarity].custom_minimum_size.x = floor(
			rarity_chances[rarity] * (BAR_WIDTH - 3))
	
