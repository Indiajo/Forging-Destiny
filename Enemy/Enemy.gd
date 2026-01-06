extends CharacterBody2D

# ---------------- STATS ----------------
@export var max_health: int = 10
@export var move_speed: float = 40.0
@export var knockback_resistance: float = 0.7
@export var attack_range: float = 24.0
@export var attack_cooldown: float = 1.2

# ---------------- NODES ----------------
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_hitbox: Area2D = $AttackHitbox

# ---------------- STATE ----------------
enum State { IDLE, CHASE, ATTACK, DEAD }
var state: State = State.IDLE

var health: int
var player: CharacterBody2D = null
var knockback_velocity: Vector2 = Vector2.ZERO
var is_locked: bool = false
var can_attack: bool = true

# ---------------- READY ----------------
func _ready():
	health = max_health

	hurtbox.area_entered.connect(_on_hurtbox_entered)
	detection_area.body_entered.connect(_on_detection_entered)
	detection_area.body_exited.connect(_on_detection_exited)

	attack_hitbox.monitoring = false
	sprite.play("Front_Idle")

# ---------------- PROCESS ----------------
func _physics_process(delta):
	if state == State.DEAD:
		return

	# Apply knockback first
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
	else:
		match state:
			State.IDLE:
				velocity = Vector2.ZERO
				if not is_locked:
					play_idle()

			State.CHASE:
				chase_player()

			State.ATTACK:
				velocity = Vector2.ZERO

	move_and_slide()

# ---------------- AI ----------------
func chase_player():
	if not player:
		state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_range and can_attack:
		start_attack()
		return

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * move_speed

	if not is_locked:
		play_walk()

# ---------------- ATTACK ----------------
func start_attack():
	state = State.ATTACK
	is_locked = true
	can_attack = false

	var attack_anim := "Front_Attack1" if randf() < 0.5 else "Front_Attack2"
	sprite.play(attack_anim)

	await get_tree().create_timer(0.15).timeout
	attack_hitbox.monitoring = true

	await sprite.animation_finished
	attack_hitbox.monitoring = false

	is_locked = false
	state = State.CHASE

	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# ---------------- ANIMATIONS ----------------
func play_idle():
	if sprite.animation != "Front_Idle":
		sprite.play("Front_Idle")

func play_walk():
	if sprite.animation != "Front_Walk":
		sprite.play("Front_Walk")

func play_hurt():
	if is_locked:
		return
	is_locked = true
	sprite.play("Front_Hurt")
	await sprite.animation_finished
	is_locked = false

func play_death():
	sprite.play("Front_Death")

# ---------------- DAMAGE ----------------
func _on_hurtbox_entered(area: Area2D):
	if not area.is_in_group("weapon_hitbox"):
		return

	var weapon = area.get_parent()
	if weapon == null:
		return

	take_damage(weapon.damage, weapon.wielder)

func take_damage(amount: int, attacker: Node2D):
	if state == State.DEAD:
		return

	health -= amount
	play_hurt()

	if attacker:
		var dir := (global_position - attacker.global_position).normalized()
		knockback_velocity = dir * 180 * knockback_resistance

	if health <= 0:
		die()

# ---------------- DEATH ----------------
func die():
	state = State.DEAD
	is_locked = true
	velocity = Vector2.ZERO
	play_death()
	await sprite.animation_finished
	queue_free()

# ---------------- DETECTION ----------------
func _on_detection_entered(body: Node2D):
	if body.is_in_group("player"):
		player = body
		state = State.CHASE

func _on_detection_exited(body: Node2D):
	if body == player:
		player = null
		state = State.IDLE
