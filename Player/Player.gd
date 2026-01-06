extends CharacterBody2D

# =================================================
# CHARACTER DATA
# =================================================
@export var character_data: CharacterData

# =================================================
# MOVEMENT STATS
# =================================================
@export var speed: float = 100.0
@export var roll_speed: float = 200.0
@export var attack_time: float = 0.35
@export var roll_time: float = 0.35
@export var stop_time: float = 0.15

# =================================================
# NODES
# =================================================
@onready var body_sprite: Sprite2D = $BodySprite
@onready var head_sprite: Sprite2D = $HeadSprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var weapon_hand: Node2D = $WeaponHand
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var camera: Camera2D = $Camera2D

var equipped_weapon_node: Node2D = null

# =================================================
# STATE
# =================================================
enum Facing { FRONT, BACK }
var facing: Facing = Facing.FRONT
var facing_right := true

var last_move_dir: Vector2 = Vector2.DOWN
var roll_direction: Vector2 = Vector2.ZERO

var is_attacking := false
var is_rolling := false
var is_stopping := false
var was_moving := false

# =================================================
# READY
# =================================================
func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	if character_data:
		apply_character(character_data)

	if anim_tree:
		anim_tree.active = true

	update_animation_parameters()

	var weapon: WeaponData = GameState.get_equipped_weapon()
	if weapon:
		equip_weapon_visual(weapon)

# =================================================
# PROCESS
# =================================================
func _physics_process(_delta):
	handle_input()
	update_animation_parameters()

func _process(delta):
	GameState.regenerate_mana(delta)

# =================================================
# CHARACTER APPLICATION
# =================================================
func apply_character(data: CharacterData):
	speed = data.move_speed
	roll_speed = data.roll_speed

	GameState.max_mana = data.max_mana
	GameState.mana = data.max_mana

	if data.body_texture:
		body_sprite.texture = data.body_texture
	if data.head_texture:
		head_sprite.texture = data.head_texture

# =================================================
# ANIMATION TREE PARAMETERS
# =================================================
func update_animation_parameters():
	var moving := velocity.length() > 0.1
	var facing_value := 0 if facing == Facing.FRONT else 1

	anim_tree.set("parameters/is_moving", moving)
	anim_tree.set("parameters/is_attacking", is_attacking)
	anim_tree.set("parameters/is_rolling", is_rolling)
	anim_tree.set("parameters/is_stopping", is_stopping)
	anim_tree.set("parameters/facing", facing_value)
	anim_tree.set("parameters/blend_position", last_move_dir)

# =================================================
# WEAPON VISUALS
# =================================================
func equip_weapon_visual(weapon: WeaponData):
	if equipped_weapon_node:
		equipped_weapon_node.queue_free()
		equipped_weapon_node = null

	if weapon.scene == null:
		return

	equipped_weapon_node = weapon.scene.instantiate()
	weapon_hand.add_child(equipped_weapon_node)

	equipped_weapon_node.wielder = self
	equipped_weapon_node.apply_weapon_data(weapon)

	update_weapon_visibility()

func update_weapon_visibility():
	if equipped_weapon_node == null:
		return

	equipped_weapon_node.visible = not is_rolling
	equipped_weapon_node.z_index = 1
	equipped_weapon_node.position = Vector2.ZERO

# =================================================
# INPUT & MOVEMENT
# =================================================
func handle_input():
	# --- ATTACK ---
	if not is_attacking and not is_rolling and not is_stopping:
		if Input.is_action_just_pressed("Attack"):
			start_attack()
			return

	# --- ROLL ---
	if not is_attacking and not is_rolling and not is_stopping:
		if Input.is_action_just_pressed("Roll"):
			start_roll()
			return

	# --- LOCKED STATES ---
	if is_attacking or is_stopping:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_rolling:
		velocity = roll_direction * roll_speed
		move_and_slide()
		return

	# --- NORMAL MOVEMENT ---
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector != Vector2.ZERO:
		last_move_dir = input_vector.normalized()
		update_facing_from_dir(last_move_dir)

	velocity = input_vector.normalized() * speed
	move_and_slide()

	if was_moving and input_vector == Vector2.ZERO and not is_stopping:
		start_stopping()

	was_moving = input_vector.length() > 0.0

# =================================================
# FACING LOGIC
# =================================================
func update_facing_from_dir(dir: Vector2):
	if abs(dir.y) >= abs(dir.x):
		facing = Facing.BACK if dir.y < 0 else Facing.FRONT

	if dir.x != 0:
		facing_right = dir.x > 0

	body_sprite.flip_h = not facing_right
	head_sprite.flip_h = not facing_right
	weapon_hand.scale.x = -1 if not facing_right else 1

# =================================================
# ACTIONS
# =================================================
func start_attack():
	is_attacking = true

	if equipped_weapon_node:
		equipped_weapon_node.visible = true
		equipped_weapon_node.is_attacking = true
		equipped_weapon_node.enable_hitbox()

	await get_tree().create_timer(attack_time).timeout

	if equipped_weapon_node:
		equipped_weapon_node.is_attacking = false
		equipped_weapon_node.disable_hitbox()

	is_attacking = false
	update_weapon_visibility()

func start_roll():
	is_rolling = true
	update_weapon_visibility()

	var dir := last_move_dir
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN

	roll_direction = dir.normalized()
	update_facing_from_dir(roll_direction)

	await get_tree().create_timer(roll_time).timeout

	is_rolling = false
	update_weapon_visibility()

func start_stopping():
	is_stopping = true
	await get_tree().create_timer(stop_time).timeout
	is_stopping = false
