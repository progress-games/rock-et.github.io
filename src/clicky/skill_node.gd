extends NinePatchRect
class_name SkillNode

const TILE_TEX := {
	ClickEffectManager.ClickType.AUTOCLICK: preload("res://clicky/tiles/autoclick.png"),
	ClickEffectManager.ClickType.BLACKHOLE: preload("res://clicky/tiles/blackhole.png"),
	ClickEffectManager.ClickType.EXPLOSION: preload("res://clicky/tiles/explosion.png"),
	ClickEffectManager.ClickType.CLICKS: preload("res://clicky/tiles/clicks.png")
}

const PATH := "res://clicky/symbols/"
const H_PADDING := 8
const V_PADDING := 6
const PRICE_GAP := 5
const MAX_LEVELS := 5
const LOCKED_COLOUR := Color(0.608, 0.671, 0.698, 1.0)
const UNLOCKED_COLOUR := Color(0.569, 0.859, 0.412, 1.0)
const PRICE_DUR := 0.15

@onready var desc := $RichTextLabel
@onready var price_rect := $Price
@onready var price := $Price/HBoxContainer/Label
@onready var level_bars := [
	$"ColorRect/HBoxContainer/1",
	$"ColorRect/HBoxContainer/2",
	$"ColorRect/HBoxContainer/3",
	$"ColorRect/HBoxContainer/4",
	$"ColorRect/HBoxContainer/5"
]

@export var id: int
@export var stat: ClickEffectManager.StatType
@export var click_type: ClickEffectManager.ClickType
@export var value: float
@export var decimal_places: int = 0
@export var operation: ClickEffectManager.UpgradeType
@export var base_price: int
@export_range(1, MAX_LEVELS) var levels: int = 1

## price is mult by this number
@export var price_scaling: float 
@export var dependencies: Array[SkillNode]

@onready var current_price := base_price

var tweens: Dictionary[String, Tween] = {
	"scale": null,
	"rotation": null,
	"price": null,
	"position": null
}

var price_pos: Dictionary
var level: int = 0

func _ready() -> void:
	texture = TILE_TEX[click_type]
	var display_operation = "+" if operation == ClickEffectManager.UpgradeType.ADD else "x"
	
	if click_type == ClickEffectManager.ClickType.CLICKS:
		stat = ClickEffectManager.StatType.EVERY
		desc.text = "+" + format_val() + get_symbol(stat)
	elif stat == ClickEffectManager.StatType.EVERY:
		desc.text = format_val() + get_symbol(stat) + "[br]+" + get_click_type(click_type)
	else:
		desc.text = get_click_type(click_type) + "[br]" + display_operation + format_val() + get_symbol(stat)
	
	set_size(Vector2(
		desc.get_content_width() + H_PADDING,
		desc.get_content_height() + V_PADDING
	))
	
	$PointLight2D.position = pivot_offset_ratio * size
	
	price.text = str(base_price)
	
	call_deferred("set_price_pos") # needs a frame to adjust text
	
	level_bars.map(func (x): x.color = LOCKED_COLOUR)
	
	for i in range(MAX_LEVELS - levels):
		level_bars[MAX_LEVELS - i - 1].visible = false
	
	mouse_entered.connect(func (): $Outline.visible = true)
	mouse_exited.connect(func (): $Outline.visible = false)

func get_symbol(s: ClickEffectManager.StatType) -> String:
	return "[img=center,center]" + PATH + ClickEffectManager.StatType.find_key(s).to_lower() + ".png[/img]"

func get_click_type(s: ClickEffectManager.ClickType) -> String:
	return "[img=center,center]" + PATH + ClickEffectManager.ClickType.find_key(s).to_lower() + ".png[/img]"

func format_val() -> String:
	if decimal_places == 0: return str(int(round(value)))
	return str(round(value * pow(10, decimal_places)) / pow(10, decimal_places))

func _process(delta: float) -> void:
	set_size(Vector2(
		desc.get_content_width() + H_PADDING,
		desc.get_content_height() + V_PADDING
	))

func set_price_pos() -> void:
	price_pos = {
		"on_hover": Vector2(
			size.x/2 - price_rect.size.x/2,
			size.y + PRICE_GAP
		),
		"off_hover": Vector2(
			size.x/2 - price_rect.size.x/2,
			PRICE_GAP
		)
	}
	price_rect.set_position(price_pos.off_hover)
	off_hover()

func on_hover() -> void:
	$Outline.visible = true
	if level == levels: return
	
	price_rect.show()
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER_POP)
	
	if tweens.price: tweens.price.kill()
	
	tweens.price = create_tween()
	tweens.price.tween_property(price_rect, "position", price_pos.on_hover, PRICE_DUR).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func off_hover() -> void:
	$Outline.visible = false
	
	if tweens.price: tweens.price.kill()
	
	tweens.price = create_tween()
	tweens.price.tween_property(price_rect, "position", price_pos.off_hover, PRICE_DUR).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tweens.price.finished.connect(price_rect.hide)

func pressed() -> void:
	if level == levels or !GameManager.can_afford(current_price, Enums.Mineral.QUARTZ) or \
	dependencies.any(func (x): return x.level != x.levels):
		play_error_tween()
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ERROR)
		return
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
	play_buy_tween()
	GameManager.add_mineral.emit(Enums.Mineral.QUARTZ, -current_price)
	
	unlock()

func unlock() -> void:
	ClickEffectManager.upgrade_effect(click_type, stat, value, operation)
	level_bars[level].color = UNLOCKED_COLOUR
	level += 1
	current_price = int(ceil(float(current_price) * price_scaling))
	price.text = str(current_price) if level != levels else "max"

func play_error_tween() -> void:
	if tweens.position: tweens.position.kill()
	
	tweens.position = create_tween()
	tweens.position.set_parallel(false)
	var base = position
	var strength = Vector2(1, 0) * [randi_range(3, 9), randi_range(-9, -3)].pick_random()
	
	tweens.position.tween_property(self, "position", base + strength, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.position.tween_property(self, "position", base - strength/4, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.position.tween_property(self, "position", base + strength/4, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.position.tween_property(self, "position", base, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func play_buy_tween() -> void:
	if tweens.rotation: tweens.rotation.kill()
	tweens.rotation = create_tween()
	tweens.rotation.set_parallel(false)
	
	var strength = [randi_range(15, 30), randi_range(-30, -15)].pick_random()
	tweens.rotation.tween_property(self, "rotation_degrees", strength, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.rotation.tween_property(self, "rotation_degrees", -strength/4, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tweens.rotation.tween_property(self, "rotation_degrees", strength/4, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tweens.rotation.tween_property(self, "rotation_degrees", 0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	if tweens.scale: tweens.scale.kill()
	tweens.scale = create_tween()
	tweens.scale.set_parallel(false)
	
	var base = Vector2(1, 1)
	strength = Vector2(1, 1) * randf_range(.1, 0.3)
	
	tweens.scale.tween_property(self, "scale", base + strength, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.scale.tween_property(self, "scale", base - strength/4, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.scale.tween_property(self, "scale", base + strength/4, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tweens.scale.tween_property(self, "scale", base, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
