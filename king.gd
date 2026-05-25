extends CharacterBody3D

@export var speed = 4.0
@export var run_speed = 8.0
@export var detect_radius = 20.0
@export var attack_radius = 2.0
@export var push_force = 15.0

var player: CharacterBody3D = null
var is_dead = false

@onready var anim_player = find_child("AnimationPlayer", true)
@onready var anim_tree = find_child("AnimationTree", true)
@onready var detection_area = $Area3D
@onready var rotate_node = find_child("root", true)

func _ready():
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is CharacterBody3D and body != self:
		player = body

func _on_body_exited(body):
	if body == player:
		player = null

func _physics_process(delta):
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	if player == null:
		anim_player.play("FIGHTIDLE_Root")
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detect_radius:
		anim_player.play("FIGHTIDLE_Root")
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	# Rör sig direkt mot spelaren
	var dir = (player.global_position - global_position).normalized()
	dir.y = 0

	var target_speed = run_speed if dist < detect_radius * 0.5 else speed
	velocity.x = dir.x * target_speed
	velocity.z = dir.z * target_speed

	# Titta mot spelaren
	if dir != Vector3.ZERO and rotate_node:
		rotate_node.basis = Basis.looking_at(dir)

	# Knuffa spelaren om nära
	if dist < attack_radius:
		var push_dir = (player.global_position - global_position).normalized()
		push_dir.y = 0.2
		player.velocity += push_dir * push_force

	move_and_slide()

	# Animation
	var current_vel = Vector2(velocity.x, velocity.z).length()
	if current_vel > run_speed * 0.5:
		anim_player.play("run_player_Root")
	elif current_vel > 0.5:
		anim_player.play("WALK_player_Root")
	else:
		anim_player.play("FIGHTIDLE_Root")

func die():
	if is_dead:
		return
	is_dead = true
	activate_ragdoll()

func activate_ragdoll():
	set_physics_process(false)
	if anim_tree:
		anim_tree.active = false
	anim_player.stop()
	var skeleton = find_child("Skeleton3D", true)
	if skeleton:
		skeleton.physical_bones_start_simulation()
	$CollisionShape3D.set_deferred("disabled", true)
