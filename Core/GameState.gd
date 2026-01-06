extends Node

# ---------- PLAYER DATA ----------
var mana: int = 100
var max_mana: int = 100
var mana_exhausted: bool = false

var inventory: Array = []          # WeaponData
var equipped_weapon_id: String = ""
func get_equipped_weapon() -> WeaponData:
	for weapon in inventory:
		if weapon.id == equipped_weapon_id:
			return weapon
	return null


func spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	return true


func regenerate_mana(delta: float):
	var regen_rate := 2 if mana_exhausted else 6
	mana += regen_rate * delta
	mana = min(mana, max_mana)

	if mana > 0:
		mana_exhausted = false

# -------- INVENTORY HELPERS --------

func add_weapon(weapon: WeaponData):
	inventory.append(weapon)


func equip_weapon(weapon_id: String) -> bool:
	for weapon in inventory:
		if weapon.id == weapon_id:
			equipped_weapon_id = weapon_id
			return true
	return false
	

func _ready():
	var sword := preload("res://weapons/data/Basic_Sword.tres")
	add_weapon(sword)
	equip_weapon("basic_sword")
