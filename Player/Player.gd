extends CharacterBody2D

# =================================================
# CHARACTER DATA
# =================================================
@export var character_data: CharacterData:
	set(value):
		character_data = value
		if is_inside_tree():
			apply_character(value)

# =================================================
# Animations
# =================================================
@export var is_idle : bool
@export var is_moving : bool
@export var is_rolling : bool


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
@onready var weapon_hand: Node2D = $WeaponHand
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var anim_tree: AnimationTree = $AnimationTree

var equipped_weapon_node: Node2D = null

# =================================================
# STATE
# =================================================
enum Facing { FRONT, BACK }
var facing: Facing = Facing.FRONT
var facing_right: bool = true

var last_move_dir: Vector2 = Vector2.DOWN
var roll_direction: Vector2 = Vector2.ZERO

var is_attacking := false
#var is_rolling := false
var is_stopping := false
var was_moving := false

# =================================================
# READY
# =================================================
func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	if character_data:
		apply_character(character_data)

	anim_tree.active = true
	
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
	if GameState.has_method("regenerate_mana"):
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
	print("Moving:", moving)

	# Parameters the StateMachine can see
	#anim_tree.set("parameters/is_moving", moving)
	#anim_tree.set("parameters/is_rolling", is_rolling)
	is_moving = moving
	
	# BlendSpaces (these were already fine)
	anim_tree.set("parameters/Movement/blend_position", last_move_dir.y)
	anim_tree.set("parameters/IdleSpace/blend_position", last_move_dir.y)
	anim_tree.set("parameters/Roll/blend_position", last_move_dir.y)

	
	
# =================================================
# INPUT & MOVEMENT
# =================================================
func handle_input():
	if is_attacking or is_stopping:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if is_rolling:
		velocity = roll_direction * roll_speed
		move_and_slide()
		return

	if Input.is_action_just_pressed("Attack"):
		start_attack()
		return
	
	if Input.is_action_just_pressed("Roll"):
		start_roll()
		return

	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_vector != Vector2.ZERO:
		last_move_dir = input_vector.normalized()
		update_facing_from_dir(last_move_dir)
		velocity = input_vector * speed
	else:
		if was_moving:
			start_stopping()
		velocity = Vector2.ZERO

	move_and_slide()
	was_moving = input_vector.length() > 0.0

# =================================================
# FACING & VISUALS
# =================================================
func update_facing_from_dir(dir: Vector2):
	if abs(dir.y) >= abs(dir.x):
		facing = Facing.BACK if dir.y < 0 else Facing.FRONT

	if dir.x != 0:
		facing_right = dir.x > 0

	body_sprite.flip_h = not facing_right
	head_sprite.flip_h = not facing_right
	weapon_hand.scale.x = 1 if facing_right else -1

func equip_weapon_visual(weapon: WeaponData):
	if equipped_weapon_node:
		equipped_weapon_node.queue_free()

	if weapon.scene:
		equipped_weapon_node = weapon.scene.instantiate()
		weapon_hand.add_child(equipped_weapon_node)
		equipped_weapon_node.wielder = self
		if equipped_weapon_node.has_method("apply_weapon_data"):
			equipped_weapon_node.apply_weapon_data(weapon)
	
	update_weapon_visibility()

func update_weapon_visibility():
	if equipped_weapon_node:
		equipped_weapon_node.visible = not is_rolling
		equipped_weapon_node.z_index = -1 if facing == Facing.BACK else 1

# =================================================
# ACTIONS
# =================================================
func start_attack():
	is_attacking = true

	if equipped_weapon_node and equipped_weapon_node.has_method("enable_hitbox"):
		equipped_weapon_node.enable_hitbox()

	await get_tree().create_timer(attack_time).timeout

	if equipped_weapon_node and equipped_weapon_node.has_method("disable_hitbox"):
		equipped_weapon_node.disable_hitbox()

	is_attacking = false

func start_roll():
	is_rolling = true
	update_weapon_visibility()
	
	roll_direction = last_move_dir
	
	await get_tree().create_timer(roll_time).timeout
	
	is_rolling = false
	update_weapon_visibility()

func start_stopping():
	is_stopping = true
	await get_tree().create_timer(stop_time).timeout
	is_stopping = false
