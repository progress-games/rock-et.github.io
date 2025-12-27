extends Resource
class_name AsteroidData

@export var asteroid_type: Enums.Asteroid
@export var start: float
@export var end: float
@export var weight: float = 1
@export var texture: Texture2D
@export var hits: Array[int] = [0, 0, 0, 0, 0]
@export var drops: Array[Enums.Mineral]
@export var custom_level_data: LevelData
@export var planets: Array[Enums.Planet]
