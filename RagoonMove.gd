extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75
@export var jump_velocity = 8.0
@export var camera: Camera3D

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("Forward"):    input_dir.z -= 1
	if Input.is_action_pressed("Backwards"): input_dir.z += 1
	if Input.is_action_pressed("Left"):      input_dir.x -= 1
	if Input.is_action_pressed("Right"):     input_dir.x += 1

	# Rörelse (bara x/z, inte y)
	var direction = Vector3.ZERO
	if (input_dir.x != 0 or input_dir.z != 0) and camera:
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		cam_forward.y = 0
		cam_right.y = 0
		direction = (cam_forward * -input_dir.z + cam_right * input_dir.x).normalized()
		$Pivot.basis = Basis.looking_at(direction)

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Gravitation
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta

	# Hopp — bara när man står på marken
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
