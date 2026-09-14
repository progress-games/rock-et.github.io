extends Control

const CHAR_SECS = 0.05

@onready var open: TextureButton = $"../ClosedBoards/Open"

@onready var next: Button = $Next
@onready var dialogue: Control = $Dialogue

@onready var exchange_runner: ExchangeRunner = $"../ExchangeRunner"
@onready var broker_rating: RichTextLabel = $"../ExchangeRunner/BrokerRating"

var full_dialogue: Array[String]
var current_idx: int = 0

@onready var transferring_mineral: TextureRect = $"../ExchangeRunner/ExchangePanel/Transfer/TransferringMineral"

@onready var increase_transfer: TextureButton = $"../ExchangeRunner/ExchangePanel/Transfer/IncreaseTransfer"
@onready var decrease_transfer: TextureButton = $"../ExchangeRunner/ExchangePanel/Transfer/DecreaseTransfer"
@onready var transfer_amount: Label = $"../ExchangeRunner/ExchangePanel/Transfer/TransferringMineral/TransferAmount"

@onready var gold_rate: TextureRect = $"../ExchangeRunner/ExchangePanel/Transfer/GoldRate"

@onready var exchange: TextureButton = $"../ExchangeRunner/ExchangePanel/Exchange"
@onready var minerals: HBoxContainer = $"../ExchangeRunner/ExchangePanel/Minerals"

@onready var amethyst: Button = $"Dialogue/7/Button"
@onready var olivine: Button = $"Dialogue/7/Button2"

func _ready() -> void:
	GameManager.tutorial_read.connect(
		func (t: Enums.Tutorial): if t == Enums.Tutorial.EXCHANGE: queue_free()
	)
	
	next.hide()
	hide()
	open.pressed.connect(
		func ():
			after(1, start)
	)
	
	next.pressed.connect(
		func ():
			current_idx += 1
			if current_idx == full_dialogue.size(): 
				queue_free()
				get_tree().paused = false
				GameManager.pause_locked = false
				GameManager.read_tutorial(Enums.Tutorial.EXCHANGE)
			else:
				dialogue.get_child(current_idx - 1).hide()
				next.hide()
				show_text(current_idx)
	)
	
	for d in dialogue.get_children():
		full_dialogue.append(d.text)
		d.text = ""
		d.hide()

func after(s: int, f: Callable) -> void:
	var t = Timer.new()
	t.timeout.connect(func (): f.call(); t.queue_free())
	add_child(t)
	t.start(s)

func start() -> void:
	get_tree().paused = true
	GameManager.pause_locked = true
	show()
	show_text(current_idx)
	exchange_runner.select_mineral(Enums.Mineral.AMETHYST)

func show_text(idx: int) -> void:
	var l = dialogue.get_child(idx)
	l.show()
	
	match idx:
		1:
			transferring_mineral.z_index = 1
		2:
			increase_transfer.z_index = 1
			decrease_transfer.z_index = 1
		3:
			transferring_mineral.z_index = 0
			increase_transfer.z_index = 0
			decrease_transfer.z_index = 0
			gold_rate.z_index = 1
			exchange_runner.transfer_amount = 10
			exchange_runner.transfer_amount_label.text = "10"
		4:
			gold_rate.z_index = 0
			broker_rating.z_index = 1
		5:
			broker_rating.z_index = 0
			exchange.z_index = 1
		6:
			minerals.z_index = 1
			exchange.z_index = 0
			
			var a = exchange_runner.exchange_rate_buttons.get(Enums.Mineral.AMETHYST)
			amethyst.global_position = a.global_position
			amethyst.size = a.size
			amethyst.mouse_entered.connect(func (): a.material.set_shader_parameter("width", 1))
			amethyst.mouse_exited.connect(func (): a.material.set_shader_parameter("width", 0))
			amethyst.pressed.connect(func (): exchange_runner.select_mineral(Enums.Mineral.AMETHYST))
			
			var o = exchange_runner.exchange_rate_buttons.get(Enums.Mineral.OLIVINE)
			olivine.global_position = o.global_position
			olivine.size = o.size
			olivine.mouse_entered.connect(func (): o.material.set_shader_parameter("width", 1))
			olivine.mouse_exited.connect(func (): o.material.set_shader_parameter("width", 0))
			olivine.pressed.connect(func (): exchange_runner.select_mineral(Enums.Mineral.OLIVINE))
		7:
			minerals.z_index = 0
	
	
	var t = create_tween()
	t.tween_property(l, "text", full_dialogue[idx], full_dialogue[idx].length() * CHAR_SECS)
	t.finished.connect(next.show)
