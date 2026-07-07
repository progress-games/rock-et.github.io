extends TextureButton
#
#const FADE_DUR := 1
#
#var flying: bool = false
#var transparency: Tween
#
#
#"""
#LOGIC:
#Takeoff is invisible
#when state changed:
	#if mission started:
		#hide embark button
		#play takeoff animation
		#set flying (currently in mission) to true
		#make takeoff fully visible
	#if mission just ended:
		#play landing animation
		#set flying to false
#
#when flying/landing animation finished:
	#if flying (mission just started):
		#play flying animation
	#else (mission just ended):
		#show embark button
#
#when planet transition begins:
	#move to just below camera
	#move takeoff from off-screen bottom to offscreen top
	#
#"""
#
#func _ready() -> void:
	#_show()
	#_fade("out", true)
	#
	#GameManager.state_changed.connect(func (s):
		#if s == Enums.State.MISSION:
			#_hide()
			#_fade("in", true)
			#_fade("out")
			#$Takeoff.play("takeoff")
			#flying = true
		#elif flying:
			#$Takeoff.play_backwards("takeoff")
			#flying = false)
	#
	#GameManager.music_changed.connect(_change_planet)
	#
	#$Takeoff.animation_finished.connect(
		#func ():
			#if $Takeoff.animation == "takeoff" and flying:
				#$Takeoff.play("flying")
			#else:
				#_fade("in")
				#_show()
	#)
#
#func _hide() -> void: self_modulate = Color.TRANSPARENT
#func _show() -> void: self_modulate = Color.WHITE
#
### "in" or "out"
#func _fade(dir: String, snap: bool = false) -> void:
	#if snap:
		#$Takeoff.modulate = Color.WHITE if dir == "in" else Color.TRANSPARENT
		#return
	#
	#if transparency: transparency.kill()
	#
	#transparency = create_tween()
	#transparency.tween_property(
		#$Takeoff, "modulate", Color.WHITE if dir == "in" else Color.TRANSPARENT, FADE_DUR
	#).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN if dir == "out" else Tween.EASE_OUT)
#
#
#
#func _change_planet(planet: Enums.Planet) -> void:
	#pass
