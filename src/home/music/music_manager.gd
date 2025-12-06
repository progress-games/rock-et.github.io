extends Node

@export var music: Array[Music]
@export var ambience: Array[Music]

func _ready() -> void:
	GameManager.state_changed.connect(
		func (s):
			for m in music:
				if s in m.listening_states and not AudioManager.music_muted:
					$Music.stop()
					$Music.stream = m.stream
					$Music.play()
			
			$Ambience.stop()
			for m in ambience:
				if s in m.listening_states and not AudioManager.ambience_muted:
					$Ambience.stream = m.stream
					$Ambience.play()
	)
