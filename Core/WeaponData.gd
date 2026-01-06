extends Resource
class_name WeaponData

@export var id: String
@export var weapon_type: String   # "sword", "axe", etc
@export var damage: int = 1

@export var sprite: Texture2D
@export var scene: PackedScene
