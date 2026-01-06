extends Resource
class_name CharacterData

@export var id: String
@export var display_name: String

# --- Core Stats ---
@export var max_health: int = 100
@export var max_mana: int = 100
@export var move_speed: float = 100.0
@export var roll_speed: float = 200.0

# --- Visuals ---
@export var sprite_frames: SpriteFrames
