extends Control

const DEFAULT_FOCUS := ClickEffectManager.ClickType.AUTOCLICK

const TILES := {
	ClickEffectManager.ClickType.AUTOCLICK: preload("res://clicky/tiles/autoclick.png"),
	ClickEffectManager.ClickType.BLACKHOLE: preload("res://clicky/tiles/blackhole.png"),
	ClickEffectManager.ClickType.EXPLOSION: preload("res://clicky/tiles/explosion.png")
}

const DESC := {
	ClickEffectManager.ClickType.AUTOCLICK: {
		ClickEffectManager.StatType.EVERY: "creates one every N clicks",
		ClickEffectManager.StatType.FREQUENCY: "clicks per second",
		ClickEffectManager.StatType.SIZE: "size relative to player hitbox",
		ClickEffectManager.StatType.DURATION: "duration in seconds"
	},
	ClickEffectManager.ClickType.BLACKHOLE: {
		ClickEffectManager.StatType.EVERY: "creates one every N clicks",
		ClickEffectManager.StatType.PULL: "blackhole pull strength",
		ClickEffectManager.StatType.SIZE: "size relative to player hitbox",
		ClickEffectManager.StatType.DURATION: "duration in seconds"
	},
	ClickEffectManager.ClickType.EXPLOSION: {
		ClickEffectManager.StatType.EVERY: "creates one every N clicks",
		ClickEffectManager.StatType.DAMAGE: "damage relative to hit strength", # deals 5x damage
		ClickEffectManager.StatType.SIZE: "size relative to player hitbox"
	}
}

@onready var tabs: Dictionary[ClickEffectManager.ClickType, TextureButton] = {
	ClickEffectManager.ClickType.AUTOCLICK: $AutoclickTab,
	ClickEffectManager.ClickType.BLACKHOLE: $BlackholeTab,
	ClickEffectManager.ClickType.EXPLOSION: $ExplosionTab
}
@onready var panel: NinePatchRect = $Panel
@onready var stats: RichTextLabel = $Panel/Stats

@onready var autoclick_locked: TextureButton = $AutoclickLocked
@onready var blackhole_locked: TextureButton = $BlackholeLocked
@onready var explosion_locked: TextureButton = $ExplosionLocked

var focus: ClickEffectManager.ClickType

func _ready() -> void:
	visible = false
	
	for effect in tabs.keys():
		var tab = tabs[effect]
		
		var bitmap := BitMap.new()
		bitmap.create_from_image_alpha(tab.texture_normal.get_image())
		tab.texture_click_mask = bitmap
		
		tab.pressed.connect(func (): set_focus(effect))
		tab.tooltip_text = ClickEffectManager.ClickType.find_key(effect).to_lower()
	
	ClickEffectManager.effect_upgraded.connect(func (f): set_focus(f))

func set_focus(f: ClickEffectManager.ClickType) -> void:
	if f == ClickEffectManager.ClickType.CLICKS: return
	
	visible = true
	match f:
		ClickEffectManager.ClickType.AUTOCLICK: autoclick_locked.visible = false
		ClickEffectManager.ClickType.BLACKHOLE: blackhole_locked.visible = false
		ClickEffectManager.ClickType.EXPLOSION: explosion_locked.visible = false
	
	tabs.values().map(func (x): x.z_index = 0)
	
	focus = f
	tabs[focus].z_index = 1
	panel.texture = TILES[focus]
	stats.text = _format_desc()

func _format_desc() -> String:
	var s = ""
	
	for stat in ClickEffectManager.stats[focus].keys():
		s += _format_stat(stat, ClickEffectManager.stats[focus][stat]) + "   "
	
	return s
	

func _format_stat(stat_type: ClickEffectManager.StatType, v: Variant) -> String:
	var s = "[hint='" + DESC[focus][stat_type] + "'][img]res://clicky/symbols/" + \
	ClickEffectManager.StatType.find_key(stat_type).to_lower() + ".png[/img][/hint] "
	
	match stat_type:
		ClickEffectManager.StatType.EVERY:
			if len(v) == 0:
				s += "N/A"
			else:
				s += v.reduce(func (a, x): return a + ", " + str(x), "").lstrip(",")
		ClickEffectManager.StatType.DURATION:
			s += r(round(v)) + "s"
		ClickEffectManager.StatType.FREQUENCY:
			s += r(v) + " p/s"
		ClickEffectManager.StatType.PULL:
			s += r(v) + " px/s"
		_: # damage and size
			s += r(v) + "x" 
	
	return s

func r(n, p=2) -> String: 
	return str(int(n)) if typeof(n) == TYPE_INT else str(round(n * pow(10, p)) / pow(10., p))
