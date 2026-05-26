extends CharacterBody3D

@export var speed = 4.0
@export var run_speed = 8.0
@export var detect_radius = 40.0
@export var attack_radius = 2.0
@export var push_force = 15.0
@export var mesh_height_offset = 1.0
@export var ragdoll_scene: PackedScene

var player: CharacterBody3D = null
var is_dead = false

@onready var anim_player = find_child("AnimationPlayer", true)
@onready var anim_tree = find_child("AnimationTree", true)
@onready var detection_area = $Area3D

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

	# Synka mesh med position
	$Pivot/Sketchfab_Scene.global_position = global_position + Vector3(0, mesh_height_offset, 0)

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	if player == null:
		if anim_player.current_animation != "FIGHTIDLE_Root":
			anim_player.play("FIGHTIDLE_Root")
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	var dist = global_position.distance_to(player.global_position)

	if dist > detect_radius:
		if anim_player.current_animation != "FIGHTIDLE_Root":
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
	if dir != Vector3.ZERO:
		var angle = atan2(dir.x, dir.z) + PI
		$Pivot/Sketchfab_Scene.rotation.y = angle

	# Knuffa spelaren om nära
	if dist < attack_radius:
		var push_dir = (player.global_position - global_position).normalized()
		push_dir.y = 0.2
		player.velocity += push_dir * push_force

	move_and_slide()

	# Animation
	var current_vel = Vector2(velocity.x, velocity.z).length()
	if current_vel > 3.0:
		if anim_player.current_animation != "run_player_Root":
			anim_player.play("run_player_Root")
	elif current_vel > 0.1:
		if anim_player.current_animation != "WALK_player_Root":
			anim_player.play("WALK_player_Root")
	else:
		if anim_player.current_animation != "FIGHTIDLE_Root":
			anim_player.play("FIGHTIDLE_Root")

func die():
	if is_dead:
		return
	is_dead = true
	activate_ragdoll()

func activate_ragdoll():
	is_dead = true
	if anim_tree:
		anim_tree.active = false
	anim_player.stop()
	$shaperuntkungen.set_deferred("disabled", true)
	
	# Spawna osynlig rigidbody på kungens position
	var rb = RigidBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1, 2, 1)
	shape.shape = box
	rb.add_child(shape)
	get_parent().add_child(rb)
	rb.global_position = global_position + Vector3(0, mesh_height_offset, 0)
	rb.apply_central_impulse(Vector3(randf_range(-2,2), 2.0, randf_range(-2,2)))
	
	# Låt meshen följa rigidbodyn varje frame
	set_process(true)
	set_meta("ragdoll_body", rb)

func _process(delta):
	if is_dead and has_meta("ragdoll_body"):
		var rb = get_meta("ragdoll_body")
		if is_instance_valid(rb):
			$Pivot/Sketchfab_Scene.global_position = rb.global_position
			$Pivot/Sketchfab_Scene.global_rotation = rb.global_rotation
