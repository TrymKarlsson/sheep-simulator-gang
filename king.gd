extends CharacterBody3D

@export var speed = 4.0
@export var run_speed = 8.0
@export var detect_radius = 40.0
@export var attack_radius = 2.0
@export var push_force = 15.0
@export var mesh_height_offset = 1.0

var player: CharacterBody3D = null
var is_dead = false
var ragdoll_body = null

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

	var dir = (player.global_position - global_position).normalized()
	dir.y = 0

	var target_speed = run_speed if dist < detect_radius * 0.5 else speed
	velocity.x = dir.x * target_speed
	velocity.z = dir.z * target_speed

	if dir != Vector3.ZERO:
		var angle = atan2(dir.x, dir.z) + PI
		$Pivot/Sketchfab_Scene.rotation.y = angle

	if dist < attack_radius:
		var push_dir = (player.global_position - global_position).normalized()
		push_dir.y = 0.2
		player.velocity += push_dir * push_force

	move_and_slide()

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
	if anim_tree:
		anim_tree.active = false
	anim_player.stop()
	$shaperuntkungen.set_deferred("disabled", true)

	var mesh = $Pivot/Sketchfab_Scene
	var saved_pos = mesh.global_position
	var saved_rot = mesh.global_rotation

	var rb = RigidBody3D.new()
	var shape = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(1, 2, 1)
	shape.shape = box
	rb.add_child(shape)
	get_parent().add_child(rb)
	rb.global_position = saved_pos
	rb.global_rotation = saved_rot

	$Pivot.remove_child(mesh)
	rb.add_child(mesh)
	mesh.position = Vector3.ZERO
	mesh.rotation = Vector3.ZERO

	# Tyngre massa = kortare flygdistans
	rb.mass = 4.0
	rb.linear_damp = 1.0
	rb.angular_damp = 0.5

	# Mindre kraft vid dödsfall
	rb.apply_central_impulse(Vector3(randf_range(-1.5, 1.5), 2.0, randf_range(-1.5, 1.5)))
	rb.apply_torque_impulse(Vector3(randf_range(-3, 3), randf_range(-1, 1), randf_range(-3, 3)))

	ragdoll_body = rb

func _process(delta):
	pass
