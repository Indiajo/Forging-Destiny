extends Node2D
class_name Weapon

@export var weapon_id: String
@export var damage: int = 1
@export var knockback_force: float = 120.0

# Front/back visual offsets relative to WeaponSocket
@export var front_offset: Vector2 = Vector2(8, 2)
@export var back_offset: Vector2 = Vector2(-8, -2)

@onready var hitbox: Area2D = $Hitbox

var wielder: CharacterBody2D
var is_attacking := false


func _ready():
	disable_hitbox()
	hitbox.area_entered.connect(_on_area_entered)


# ---------------- DATA APPLICATION ----------------

func apply_weapon_data(data: WeaponData) -> void:
	weapon_id = data.id
	damage = data.damage

	if data.sprite:
		$Sprite2D.texture = data.sprite


# ---------------- FRONT/BACK OFFSETS ----------------

func update_facing(is_front: bool) -> void:
	if is_front:
		position = front_offset
		z_index = 1   # draw in front
	else:
		position = back_offset
		z_index = -1  # draw behind


# ---------------- HITBOX CONTROL ----------------

func enable_hitbox() -> void:
	hitbox.monitoring = true
	hitbox.monitorable = true


func disable_hitbox() -> void:
	hitbox.monitoring = false
	hitbox.monitorable = false


# ---------------- COLLISIONS ----------------

func _on_area_entered(area: Area2D) -> void:
	# Block projectiles (only while hitbox is enabled)
	if area.is_in_group("projectile"):
		area.queue_free()
		return

	# Weapon clash
	var other_weapon := area.get_parent()
	if other_weapon and other_weapon != self and other_weapon.has_method("on_weapon_clash"):
		other_weapon.on_weapon_clash(self)


func on_weapon_clash(other_weapon) -> void:
	if not is_attacking or not other_weapon.is_attacking:
		return

	if wielder == null or other_weapon.wielder == null:
		return

	var dir: Vector2 = (wielder.global_position - other_weapon.wielder.global_position).normalized()
	wielder.velocity += dir * knockback_force
	other_weapon.wielder.velocity -= dir * knockback_force
