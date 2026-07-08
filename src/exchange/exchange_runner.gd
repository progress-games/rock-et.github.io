extends Control
class_name ExchangeRunner

const MAX_TRANSFER_AMOUNT = 10000;
const MIN_TRANSFER_AMOUNT = 10;
const EXCHANGE_TICK_RATE = 0.1;
const EXCHANGE_DURATION = 5;

const EXCHANGE_RATE_BUTTON = preload("uid://d01jqc0bfrtdu")

@export var exchange_rates: Dictionary[Enums.Mineral, ExchangeRate]

@onready var minerals: VBoxContainer = $Minerals

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

var exchange_rate_buttons: Dictionary[Enums.Mineral, ExchangeRateButton]
var exchange_tick_timer: Timer
var selected_mineral: Enums.Mineral = Enums.Mineral.AMETHYST
var transfer_amount: int = 10

func _ready() -> void:
	transfer_amount_label.text = str(transfer_amount)
	minerals.get_children().map(func (x): x.queue_free())
	
	for mineral in exchange_rates.keys():
		var new_button = EXCHANGE_RATE_BUTTON.instantiate() as ExchangeRateButton
		minerals.add_child(new_button)
		new_button.set_mineral(mineral)
		new_button.pressed.connect(func (): select_mineral(mineral))
		exchange_rate_buttons.set(mineral, new_button)
	
	exchange_tick_timer = Timer.new()
	exchange_tick_timer.wait_time = EXCHANGE_TICK_RATE
	exchange_tick_timer.timeout.connect(update_rates)
	add_child(exchange_tick_timer)
	
	start_new_exchange()

func exchange() -> void:
	if GameManager.player.can_afford(transfer_amount, selected_mineral):
		GameManager.add_mineral.emit(selected_mineral, -transfer_amount)
		GameManager.add_mineral.emit(Enums.Mineral.GOLD, exchange_rates[selected_mineral].current * transfer_amount)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)

func hover(b: String) -> void:
	match b:
		"increase": increase_transfer.material.set_shader_parameter("width", 1)
		"decrease": decrease_transfer.material.set_shader_parameter("width", 1)
		"exchange": exchange_button.material.set_shader_parameter("width", 1)
	
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)

func off_hover(b: String) -> void:
	match b:
		"increase": increase_transfer.material.set_shader_parameter("width", 0)
		"decrease": decrease_transfer.material.set_shader_parameter("width", 0)
		"exchange": exchange_button.material.set_shader_parameter("width", 0)
	
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
	if exchange_rate_buttons[m].is_locked: return
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
	for m in exchange_rates.keys():
		var rate = exchange_rates[m]
		if exchange_rate_buttons[m].is_locked: continue
		rate.new_rate()
		exchange_rate_buttons[m].update_value(rate.current)
	
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
	exchange_tick_timer.start()

func end_exchange() -> void:
	exchange_tick_timer.stop()
	
	exchange_rates.values().map(func (x): x.reset_rate())
	
	GameManager.clear_inventory.emit()
	GameManager.show_mineral.emit(Enums.Mineral.GOLD)
