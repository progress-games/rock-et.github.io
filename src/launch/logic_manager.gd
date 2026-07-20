extends Node2D

@export var panels: Dictionary[Node, LaunchPanel]
@export var minerals: Dictionary[Enums.Planet, Enums.Mineral]

@onready var boost: Node2D = $Boost
@onready var boost_display: Node2D = $Boost/BoostDisplay
@onready var launch: TextureButton = $Launch

var progress: float

func _ready() -> void:
	GameManager.state_changed.connect(func (s):
		if s == Enums.State.LAUNCH:
			boost._set_progress(0)
			GameManager.show_mineral.emit(minerals[GameManager.planet])
	)
	
	GameManager.planet_changed.connect(func (p):
		for n in panels.keys():
			n.visible = p in panels[n].planets
			)
	
	launch.mouse_entered.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	launch.mouse_exited.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))

func get_boost_price() -> float:
	return floor(pow(progress * 100, 1.4) * (1 - StatManager.get_stat("boost_discount").value))

func _on_launch_pressed() -> void:
	if !GameManager.player.can_afford(get_boost_price(), Enums.Mineral.CORUNDUM):
		return
	
	var boost_amount = DrinksManager.get_stat(DrinkModifier.ModifyingStat.INITIAL_BOOST)
	
	if boost.visible:
		boost_amount += boost_display.progress * boost_display.MAX_BOOST_DIS
		var cost := get_boost_price()
		GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, -1 * cost)
		GameManager.state_changed.emit(Enums.State.MISSION)
		GameManager.boost.emit(boost_amount)
		GameManager.clear_inventory.emit()
		return
	
	if boost_amount > 0:
		GameManager.boost.emit(boost_amount)
	GameManager.state_changed.emit(Enums.State.MISSION)

func _on_boost_display_progress_changed(p: float) -> void:
	progress = p
	launch.disabled = !GameManager.player.can_afford(get_boost_price(), Enums.Mineral.CORUNDUM)
