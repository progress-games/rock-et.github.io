extends Control
class_name ExchangeRunner

const HOLD = "[outline_size=5][outline_color=FFFFFF][color=ae2334]HOLD "
const BUY = "[outline_size=5][outline_color=FFFFFF][color=f9c22b]BUY "
const STRONG_BUY = "[outline_size=5][outline_color=FFFFFF][color=165a4c][shake rate=20.0 level=1 connected=1]STRONG BUY"

const NOT_ENOUGH = "[wave amp=20 freq=10]not enough "

const MAX_TRANSFER_AMOUNT = 10000;
const MIN_TRANSFER_AMOUNT = 10;
const EXCHANGE_TICK_RATE = 0.1;
const EXCHANGE_DURATION = 5;
const EXCHANGE_DELAY = 0.3;

const MINERAL_SWITCH = preload("uid://b2uxauk1467kf")
const REPLACEMENT_AND_OUTLINE = preload("uid://bdsus7hm4q1wt")

@export var exchange_rates: Dictionary[Enums.Mineral, ExchangeRate]

@onready var transfer_amount_label: Label = $ExchangePanel/Transfer/TransferringMineral/TransferAmount
@onready var rate_amount: Label = $ExchangePanel/Transfer/GoldRate/RateAmount

@onready var increase_transfer: TextureButton = $ExchangePanel/Transfer/IncreaseTransfer
@onready var decrease_transfer: TextureButton = $ExchangePanel/Transfer/DecreaseTransfer

@onready var graph: ColorRect = $ExchangePanel/Graph/Graph

@onready var graph_panel: NinePatchRect = $ExchangePanel/Graph
@onready var transferring_mineral_panel: TextureRect = $ExchangePanel/Transfer/TransferringMineral
@onready var transferring_mineral: TextureRect = $ExchangePanel/Transfer/TransferringMineral/TextureRect

@onready var exchange_mineral: TextureRect = $ExchangePanel/Exchange/Mineral
@onready var exchange_button: TextureButton = $ExchangePanel/Exchange

@onready var minerals: HBoxContainer = $ExchangePanel/Minerals
@onready var broker_rating: RichTextLabel = $BrokerRating
@onready var not_enough: RichTextLabel = $NotEnough

var exchange_rate_buttons: Dictionary[Enums.Mineral, TextureButton]

var exchange_tick_timer: Timer
var selected_mineral: Enums.Mineral = Enums.Mineral.AMETHYST
var transfer_amount: int = 10

var exchange_delay_time := 0.

func _ready() -> void:
	broker_rating.text = ""
	
	transfer_amount_label.text = str(transfer_amount)
	
	exchange_tick_timer = Timer.new()
	exchange_tick_timer.wait_time = EXCHANGE_TICK_RATE
	exchange_tick_timer.timeout.connect(update_rates)
	add_child(exchange_tick_timer)
	
	start_new_exchange()

func erase_mineral_buttons() -> void:
	minerals.get_children().map(func (x): x.queue_free())
	exchange_rate_buttons.clear()

func setup_mineral_buttons() -> void:
	erase_mineral_buttons()
	
	var outline = ShaderMaterial.new()
	outline.shader = REPLACEMENT_AND_OUTLINE
	outline.set_shader_parameter("original_colors", get_mineral_colours(Enums.Mineral.TOPAZ))
	
	for mineral in exchange_rates.keys():
		var texture_button = TextureButton.new()
		texture_button.texture_normal = MINERAL_SWITCH
		texture_button.material = outline.duplicate()
		texture_button.material.set_shader_parameter("replacement_colors", get_mineral_colours(mineral))
		texture_button.material.set_shader_parameter("width", 0)
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = GameManager.mineral_data[mineral].texture
		
		if GameManager.player.has_discovered_mineral(mineral):
			texture_button.mouse_entered.connect(func (): hover(Enums.Mineral.find_key(mineral)))
			texture_button.mouse_exited.connect(func (): off_hover(Enums.Mineral.find_key(mineral)))
			texture_button.pressed.connect(func (): select_mineral(mineral))
		else:
			texture_button.material = null
			texture_button.modulate = Color(0, 0, 0, 0.3)
		
		texture_button.add_child(texture_rect)
		minerals.add_child(texture_button)
		
		texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		exchange_rate_buttons.set(mineral, texture_button)

func get_mineral_colours(m: Enums.Mineral) -> Array[Color]:
	var d = GameManager.mineral_data[m]
	return [
		d.dark_colour,
		d.mid_colour,
		d.light_colour
	]

func _process(delta: float) -> void:
	if exchange_delay_time <= 0: return
	exchange_delay_time -= delta
	exchange_button.material.set_shader_parameter("progress", 1 - exchange_delay_time / EXCHANGE_DELAY)

func exchange() -> void:
	if exchange_delay_time > 0:
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.ERROR)
		return
	
	if GameManager.player.can_afford(transfer_amount, selected_mineral):
		GameManager.add_mineral.emit(selected_mineral, -transfer_amount)
		GameManager.add_mineral.emit(Enums.Mineral.GOLD, exchange_rates[selected_mineral].current * transfer_amount)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
		
		exchange_delay_time = EXCHANGE_DELAY
	else:
		not_enough.text = NOT_ENOUGH + Enums.Mineral.find_key(selected_mineral).to_lower() + "!"
		not_enough.modulate = Color.WHITE
		var t = create_tween()
		t.tween_property(not_enough, "modulate", Color.TRANSPARENT, 1)

func hover(b: String) -> void:
	match b:
		"increase": increase_transfer.material.set_shader_parameter("width", 1)
		"decrease": decrease_transfer.material.set_shader_parameter("width", 1)
		"exchange": exchange_button.material.set_shader_parameter("width", 1)
		_: exchange_rate_buttons[Enums.Mineral[b]].material.set_shader_parameter("width", 1)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b: String) -> void:
	match b:
		"increase": increase_transfer.material.set_shader_parameter("width", 0)
		"decrease": decrease_transfer.material.set_shader_parameter("width", 0)
		"exchange": exchange_button.material.set_shader_parameter("width", 0)
		_: exchange_rate_buttons[Enums.Mineral[b]].material.set_shader_parameter("width", 0)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func increase_transfer_amount() -> void:
	transfer_amount = max(transfer_amount * 10 % (MAX_TRANSFER_AMOUNT * 10), MIN_TRANSFER_AMOUNT)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	transfer_amount_label.text = str(transfer_amount)

func decrease_transfer_amount() -> void:
	transfer_amount /= 10
	if transfer_amount < MIN_TRANSFER_AMOUNT: transfer_amount = MAX_TRANSFER_AMOUNT
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUTTON_DOWN)
	transfer_amount_label.text = str(transfer_amount)

func select_mineral(m: Enums.Mineral) -> void:
	#if exchange_rate_buttons[m].is_locked: return
	GameManager.clear_inventory.emit()
	GameManager.show_mineral.emit(Enums.Mineral.GOLD)
	GameManager.show_mineral.emit(m)
	selected_mineral = m
	
	var mineral_data = GameManager.mineral_data[m]
	graph.color = mineral_data.dark_colour
	graph_panel.material.set_shader_parameter("replacement_colors", [mineral_data.dark_colour, mineral_data.mid_colour])
	transferring_mineral_panel.material.set_shader_parameter("replacement_colors", [mineral_data.dark_colour, mineral_data.mid_colour])
	exchange_mineral.texture = mineral_data.texture
	transferring_mineral.texture = mineral_data.texture

func update_rates() -> void:
	#for m in exchange_rates.keys():
		#var rate = exchange_rates[m]
		#if exchange_rate_buttons[m].is_locked: continue
		#rate.new_rate()
		#exchange_rate_buttons[m].update_value(rate.current)
	#
	
	exchange_rates.values().map(func (x): x.new_rate())
	
	var rate = exchange_rates[selected_mineral]
	
	if rate.current < rate.mean * 0.75:
		broker_rating.text = HOLD
	elif rate.current < rate.mean * 2.:
		broker_rating.text = BUY
	else:
		broker_rating.text = STRONG_BUY
	
	update_graph()

func update_graph() -> void:
	var selected_rate = exchange_rates[selected_mineral]
	var past_rates = selected_rate.past_rates_normalised.duplicate()
	if past_rates.size() < selected_rate.STORE_AMOUNT:
		for i in range(selected_rate.STORE_AMOUNT - past_rates.size()):
			past_rates.push_front(0)
	
	graph.material.set_shader_parameter("values", past_rates)
	rate_amount.text = str(round(selected_rate.current * transfer_amount * 10) / 10)

func start_new_exchange() -> void:
	setup_mineral_buttons()
	minerals.show()
	exchange_tick_timer.start()
	select_mineral(Enums.Mineral.AMETHYST)

func end_exchange() -> void:
	broker_rating.text = ""
	
	minerals.hide()
	exchange_tick_timer.stop()
	
	exchange_rates.values().map(func (x): x.reset_rate())
	
	GameManager.clear_inventory.emit()
	GameManager.show_mineral.emit(Enums.Mineral.GOLD)
