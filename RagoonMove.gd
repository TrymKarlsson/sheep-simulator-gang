extends CharacterBody3D

@export var speed = 8.0
@export var run_speed = 16.0
@export var slow_speed = 4.0
@export var fall_acceleration = 75.0
@export var jump_velocity = 8.0
@export var turn_speed = 10.0
@export var brake_speed = 15.0
@export var acceleration = 3.0
@export var camera: Camera3D
@export var emote_wheel: Control

var smooth_direction = Vector3.ZERO
var smooth_speed = 0.0
var is_jumping = false
var is_emoting = false

@onready var anim_tree = $Pivot/Sketchfab_Scene/AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = $Pivot/Sketchfab_Scene/AnimationTree.get("parameters/StateMachine/playback")

func _ready():
	print(anim_state)
	if emote_wheel:
		emote_wheel.hide()

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("Forward"):    input_dir.z -= 1
	if Input.is_action_pressed("Backwards"): input_dir.z += 1
	if Input.is_action_pressed("Left"):      input_dir.x -= 1
	if Input.is_action_pressed("Right"):     input_dir.x += 1

	var target_speed
	if Input.is_action_pressed("Run"):
		target_speed = run_speed
	elif Input.is_action_pressed("Sneak"):
		target_speed = slow_speed
	else:
		target_speed = speed

	if input_dir == Vector3.ZERO:
		target_speed = 0.0

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

	# Hopp
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_emoting:
		velocity.y = jump_velocity
		is_jumping = true
		anim_state.travel("jump")

	if is_jumping and is_on_floor() and velocity.y <= 0:
		is_jumping = false
		anim_state.travel("locomotion")

	# Visa hjulet medan B hålls in
	if emote_wheel:
		if Input.is_action_pressed("EmoteWheel") and is_on_floor() and not is_jumping and not is_emoting:
			emote_wheel.show()
		else:
			emote_wheel.hide()

	# Trigga animation när B släpps
	if Input.is_action_just_released("EmoteWheel") and is_on_floor() and not is_jumping:
		if emote_wheel:
			var chosen = emote_wheel.get_selected_emote()
			if chosen != "" and not is_emoting:
				is_emoting = true
				anim_state.travel(chosen)

	# Avbryt emote om man rör sig
	if is_emoting and input_dir != Vector3.ZERO:
		is_emoting = false
		anim_state.travel("locomotion")

	move_and_slide()

	# Animation blend
	if not is_jumping and not is_emoting:
		var current_velocity = Vector2(velocity.x, velocity.z).length()
		var blend = 0.0
		if current_velocity > 0.1:
			blend = clamp(remap(current_velocity, 0.0, run_speed, 0.0, 1.0), 0.0, 1.0)
		anim_tree.set("parameters/StateMachine/locomotion/blend_position", blend)
