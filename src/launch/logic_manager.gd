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
			set_visible_panels()
	)
	
	panels.keys().map(func (x): x.visible = false)
	
	GameManager.planet_changed.connect(set_visible_panels)
	
	launch.mouse_entered.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.HOVER)
		AudioManager.create_audio(SoundEffect.SOUND_EFFECT_TYPE.HOVER))
	launch.mouse_exited.connect(func (): 
		GameManager.set_mouse_state.emit(Enums.MouseState.DEFAULT))

func set_visible_panels(_p=0) -> void:
	for n in panels.keys():
		var req = panels[n]
		n.visible = GameManager.planet in req.planets && \
			(req.requirement == LaunchPanel.PanelRequirement.STATE && \
			GameManager.player.has_discovered_state(req.required_state)) || \
			(req.requirement == LaunchPanel.PanelRequirement.BOUGHT_POTION &&
			(n.visible || GameManager.player.owned_potions.size() > 0))
		

func get_boost_price() -> float:
	return floor((progress * 100) * 15 * (1 - StatManager.get_stat("boost_discount").value))

func _on_launch_pressed() -> void:
	if GameManager.state == Enums.State.MISSION: return
	if !GameManager.player.can_afford(get_boost_price(), Enums.Mineral.CORUNDUM):
		return
	
	if boost.visible:
		var cost := get_boost_price()
		GameManager.add_mineral.emit(Enums.Mineral.CORUNDUM, -1 * cost)
		GameManager.state_changed.emit(Enums.State.MISSION)
		GameManager.boost.emit(boost_display.progress * boost_display.MAX_BOOST_DIS)
		GameManager.clear_inventory.emit()
		return
	
	GameManager.state_changed.emit(Enums.State.MISSION)
	
	
	var boost_amount: float = \
		DrinksManager.get_stat(DrinkModifier.ModifyingStat.INITIAL_BOOST) \
		/ GameManager.DISTANCES[GameManager.planet]
	
	if boost_amount > 0.:
		GameManager.boost.emit(boost_amount)
	

func _on_boost_display_progress_changed(p: float) -> void:
	progress = p
	launch.disabled = !GameManager.player.can_afford(get_boost_price(), Enums.Mineral.CORUNDUM)
