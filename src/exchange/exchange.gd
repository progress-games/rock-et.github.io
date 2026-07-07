extends Control

const MARKET_OPEN_TEXT = "[outline_size=5][outline_color=FFFFFF][color=165a4c][shake rate=20.0 level=1 connected=1]MARKET OPEN"
const MARKET_CLOSED_TEXT = "[outline_size=5][outline_color=FFFFFF][color=ae2334]MARKET CLOSED"

const SWING_DUR = 0.5
const MIN_SWING = 0.25
const MAX_SWING = 0.5
const BOARD_DUR = 0.2
const CLOSE_BOARD = Vector2(43, 0)
const OPEN_BOARD = Vector2(43, -166)

const PRICE_DUR = 0.2
const HIDE_PRICE_Y = 10
const SHOW_PRICE_Y = -25
const PRICE_SCALE = 0.8
const HIDE_DUR_Y = 12
const SHOW_DUR_Y = -44

@onready var exchange_runner: ExchangeRunner = $ExchangeRunner
@onready var board_string: Line2D = $ClosedBoards/BoardString
@onready var open_board: TextureButton = $ClosedBoards/Open
@onready var nail: Sprite2D = $ClosedBoards/Nail
@onready var closed_boards: TextureRect = $ClosedBoards
@onready var market_open: RichTextLabel = $MarketOpen

@onready var clock: TextureButton = $Clock
@onready var clock_hand: Sprite2D = $Clock/ClockHand
@onready var second_hand: Sprite2D = $Clock/SecondHand

@onready var price_panel: NinePatchRect = $Clock/Price
@onready var price_label: Label = $Clock/Price/Label
@onready var duration_panel: NinePatchRect = $Clock/Duration
@onready var duration_label: Label = $Clock/Duration/Label

@onready var close_tab: TextureButton = $CloseTab

var exchange_running := false

var exchange_duration_timer: Timer

func _ready() -> void:
	open_board.mouse_entered.connect(func (): set_outline(open_board, true))
	open_board.mouse_exited.connect(func (): set_outline(open_board, false))
	
	clock.mouse_entered.connect(func (): set_outline(clock, true); show_clock_upgrades())
	clock.mouse_exited.connect(func (): set_outline(clock, false); hide_clock_upgrades())
	clock.pressed.connect(func (): 
		var stat = StatManager.get_stat("exchange_duration")
		if GameManager.can_afford(stat.cost, Enums.Mineral.GOLD):
			GameManager.add_mineral.emit(Enums.Mineral.GOLD, -stat.cost)
			StatManager.upgrade_stat("exchange_duration")
			AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.BUY)
			update_clock_stats()
		)
	
	exchange_duration_timer = Timer.new()
	exchange_duration_timer.one_shot = true
	exchange_duration_timer.timeout.connect(close_market)
	add_child(exchange_duration_timer)
	
	GameManager.day_changed.connect(func (_d): enable_market())
	
	close_market()
	hide_clock_upgrades()
	enable_market()

func update_clock_stats() -> void:
	price_label.text = str(StatManager.get_stat("exchange_duration").display_cost)
	duration_label.text = str(StatManager.get_stat("exchange_duration").display_value)

func set_outline(n: Control, outline: bool) -> void:
	if n.disabled: return
	n.material.set_shader_parameter("width", 1 if outline else 0)
	if outline: AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER)
	GameManager.set_mouse_state.emit(Enums.MouseState.HOVER if outline else Enums.MouseState.DEFAULT)

func show_clock_upgrades() -> void:
	if exchange_running: return
	var p = create_tween()
	var s = create_tween()
	var d = create_tween()
	
	p.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	s.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	d.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	p.tween_property(price_panel, "position:y", SHOW_PRICE_Y, PRICE_DUR)
	s.tween_property(price_panel, "scale", Vector2.ONE, PRICE_DUR)
	d.tween_property(duration_panel, "position:y", SHOW_DUR_Y, PRICE_DUR)
	
	update_clock_stats()

func hide_clock_upgrades() -> void:
	var p = create_tween()
	var s = create_tween()
	var d = create_tween()
	
	p.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	s.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	d.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	p.tween_property(price_panel, "position:y", HIDE_PRICE_Y, PRICE_DUR)
	s.tween_property(price_panel, "scale", Vector2(PRICE_SCALE, PRICE_SCALE), PRICE_DUR)
	d.tween_property(duration_panel, "position:y", HIDE_DUR_Y, PRICE_DUR)

func enable_market() -> void:
	open_board.disabled = false
	open_board.position.x = nail.position.x - open_board.size.x / 2
	open_board.pivot_offset = Vector2(
		open_board.texture_normal.get_size().x * 0.5,
		open_board.texture_normal.get_size().y * -0.8
	)
	swing_sign()

func disable_market() -> void:
	open_board.disabled = true
	open_board.position.x = nail.position.x - open_board.texture_disabled.get_size().x / 2
	open_board.pivot_offset = Vector2(
		open_board.texture_disabled.get_size().x * 0.5,
		open_board.texture_disabled.get_size().y * -0.8
	)

func _process(_d: float) -> void:
	var w = open_board.texture_disabled.get_size().x if open_board.disabled else open_board.size.x
	board_string.points = [
		(open_board.position - nail.position).rotated(open_board.rotation) + nail.position, 
		nail.position,
		(open_board.position + Vector2(w, 0) - nail.position).rotated(open_board.rotation) + nail.position
	]
	
	if exchange_running:
		clock_hand.rotation = -1 * 2 * PI * exchange_duration_timer.time_left / exchange_duration_timer.wait_time
		second_hand.rotation = -1 * 2 * PI * fmod(exchange_duration_timer.time_left, 1.)

func open_market() -> void:
	var board_tween = create_tween()
	board_tween.tween_property(closed_boards, "position", OPEN_BOARD, BOARD_DUR)
	market_open.text = MARKET_OPEN_TEXT
	
	AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.EXCHANGE_BG)
	
	exchange_duration_timer.wait_time = StatManager.get_stat("exchange_duration").value
	exchange_duration_timer.start()
	exchange_runner.start_new_exchange()
	exchange_running = true
	close_tab.visible = false
	clock.disabled = true
	clock_hand.visible = true
	second_hand.visible = true

func close_market() -> void:
	var board_tween = create_tween()
	board_tween.tween_property(closed_boards, "position", CLOSE_BOARD, BOARD_DUR).set_ease(Tween.EASE_IN_OUT).finished.connect(
		swing_sign
	)
	market_open.text = MARKET_CLOSED_TEXT
	AudioManager.stop_audio(SoundEffect.SOUND_EFFECT_TYPE.EXCHANGE_BG)
	if exchange_running:
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.DOOR_CLOSE)
	
	disable_market()
	exchange_runner.end_exchange()
	exchange_running = false
	close_tab.visible = true
	clock.disabled = false
	clock_hand.visible = false
	second_hand.visible = false

func swing_sign() -> void:
	var swing = create_tween()
	var bounce = create_tween()
	
	bounce.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	swing.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	var angle = randf_range(MIN_SWING, MAX_SWING) * [-1., 1.].pick_random()
	
	swing.tween_property(open_board, "rotation", angle, 0.25)
	swing.tween_property(open_board, "rotation", -angle * 0.75, 0.35)
	swing.tween_property(open_board, "rotation", angle * 0.45, 0.30)
	swing.tween_property(open_board, "rotation", angle * 0.25, 0.25)
	
	bounce.tween_property(open_board, "scale", Vector2(1.04, 0.91), 0.08)
	bounce.tween_property(open_board, "scale", Vector2(0.98, 1.02), 0.07)
	bounce.tween_property(open_board, "scale", Vector2.ONE, 0.10)
	
