extends CharacterBody3D

@export var speed = 8.0
@export var run_speed = 16.0
@export var slow_speed = 4.0
@export var fall_acceleration = 75.0
@export var jump_velocity = 8.0
@export var turn_speed = 10.0
@export var brake_speed = 15.0
@export var acceleration = 3.0  # hur snabbt man når tophastighet (lägre = trögare)
@export var camera: Camera3D

var smooth_direction = Vector3.ZERO
var smooth_speed = 0.0  # nuvarande hastighet som lerpar

@onready var anim_tree = $Pivot/Sketchfab_Scene/AnimationTree

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("Forward"):    input_dir.z -= 1
	if Input.is_action_pressed("Backwards"): input_dir.z += 1
	if Input.is_action_pressed("Left"):      input_dir.x -= 1
	if Input.is_action_pressed("Right"):     input_dir.x += 1

	# Målhastighet beroende på input
	var target_speed
	if Input.is_action_pressed("Run"):
		target_speed = run_speed
	elif Input.is_action_pressed("Sneak"):
		target_speed = slow_speed
	else:
		target_speed = speed

	# Om ingen input — bromsa mot 0
	if input_dir == Vector3.ZERO:
		target_speed = 0.0

	# Lerpa smooth_speed mot target_speed
	smooth_speed = lerp(smooth_speed, target_speed, acceleration * delta)

	var direction = Vector3.ZERO
	if (input_dir.x != 0 or input_dir.z != 0) and camera:
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		cam_forward.y = 0
		cam_right.y = 0
		direction = (cam_forward * -input_dir.z + cam_right * input_dir.x).normalized()

	if direction != Vector3.ZERO:
		smooth_direction = smooth_direction.lerp(direction, turn_speed * delta)
		$Pivot.basis = Basis.looking_at(smooth_direction)
	else:
		smooth_direction = smooth_direction.lerp(Vector3.ZERO, brake_speed * delta)

	velocity.x = smooth_direction.x * smooth_speed
	velocity.z = smooth_direction.z * smooth_speed

	if not is_on_floor():
		velocity.y -= fall_acceleration * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()

	# Animation blend
	var current_velocity = Vector2(velocity.x, velocity.z).length()
	var blend = 0.0
	if current_velocity > 0.1:
		blend = clamp(remap(current_velocity, 0.0, run_speed, 0.0, 1.0), 0.0, 1.0)
	anim_tree.set("parameters/stillwalkrunblend/blend_position", blend)
	print(blend)
