extends Resource
class_name PowerupData

@export var small: Texture2D
@export var big: Texture2D

@export var colours: Dictionary[String, Color] = {
	"dark": Color.WHITE,
	"mid": Color.WHITE,
	"light": Color.WHITE,
	"shine": Color.WHITE
}
