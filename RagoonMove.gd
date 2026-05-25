extends CharacterBody3D
@export var speed = 8.0
@export var run_speed = 16.0
@export var slow_speed = 4.0
@export var fall_acceleration = 75.0
@export var jump_velocity = 8.0
@export var turn_speed = 10.0
@export var brake_speed = 15.0
@export var acceleration = 3.0
@export var push_force = 8.0
@export var push_up = 0.3
@export var rod_lunge = 20.0
@export var camera: Camera3D
@export var emote_wheel: Control

var smooth_direction = Vector3.ZERO
var smooth_speed = 0.0
var is_jumping = false
var is_emoting = false
var emote_frozen = false
var is_rodding = false
var rod_timer = 0.0
var rod_lunge_dir = Vector3.ZERO
var current_emote = ""
var one_shot_emotes = ["death_emote", "stand_to_sitting_emote"]

@onready var anim_tree = $Pivot/Sketchfab_Scene/AnimationTree
@onready var anim_state: AnimationNodeStateMachinePlayback = $Pivot/Sketchfab_Scene/AnimationTree.get("parameters/StateMachine/playback")

func _ready():
	if not camera:
		camera = get_viewport().get_camera_3d()
	if emote_wheel:
		emote_wheel.hide()

func _physics_process(delta):
	var input_dir = Vector3.ZERO
	if Input.is_action_pressed("Forward"):    input_dir.z -= 1
	if Input.is_action_pressed("Backwards"): input_dir.z += 1
	if Input.is_action_pressed("Left"):      input_dir.x -= 1
	if Input.is_action_pressed("Right"):     input_dir.x += 1

	var target_speed = speed
	if Input.is_action_pressed("Run"):
		target_speed = run_speed
	elif Input.is_action_pressed("Sneak"):
		target_speed = slow_speed
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
	if Input.is_action_just_pressed("Jump") and is_on_floor() and not is_emoting and not emote_frozen and not is_rodding:
		velocity.y = jump_velocity
		is_jumping = true
		is_emoting = false
		emote_frozen = false
		current_emote = ""
		anim_tree.active = true
		anim_state.start("jump")
	if is_jumping and is_on_floor() and velocity.y <= 0:
		is_jumping = false
		anim_state.start("locomotion")

	# Stånga – starta
	if Input.is_action_just_pressed("Rod") and is_on_floor() and not is_jumping and not is_emoting and not is_rodding:
		is_rodding = true
		rod_timer = 0.0
		rod_lunge_dir = -$Pivot.global_transform.basis.z
		rod_lunge_dir.y = 0
		rod_lunge_dir = rod_lunge_dir.normalized()
		anim_tree.active = true
		anim_state.start("rod_emote")

	# Stånga – räkna timer och applicera luns vid rätt tidpunkt
	if is_rodding:
		rod_timer += delta
		# Applicera acceleration under en kort period istället för teleport
		if rod_timer >= 0.4 and rod_timer <= 0.5:
			velocity += rod_lunge_dir * rod_lunge
		# Kolla om animationen är klar
		var node = anim_state.get_current_node()
		if node != "rod_emote" and rod_timer > 0.3:
			is_rodding = false
			anim_state.start("locomotion")

	# Kolla om one-shot emote är klar – frys AnimationTree på sista frame
	if is_emoting and current_emote in one_shot_emotes:
		var node = anim_state.get_current_node()
		if node != current_emote:
			is_emoting = false
			emote_frozen = true
			anim_tree.active = false

	# Avbryt emote/frys om man rör sig
	if (is_emoting or emote_frozen) and input_dir != Vector3.ZERO:
		is_emoting = false
		emote_frozen = false
		current_emote = ""
		anim_tree.active = true
		anim_state.start("locomotion")

	# Visa hjulet
	if emote_wheel:
		if Input.is_action_pressed("EmoteWheel") and is_on_floor() and not is_jumping:
			emote_wheel.show()
		else:
			emote_wheel.hide()

	# Trigga emote
	if Input.is_action_just_released("EmoteWheel") and is_on_floor() and not is_jumping:
		if emote_wheel:
			var chosen = emote_wheel.get_selected_emote()
			if chosen != "":
				is_emoting = true
				emote_frozen = false
				current_emote = chosen
				anim_tree.active = true
				anim_state.start(chosen)

	move_and_slide()

	# Knuffa RigidBody3D-objekt
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody3D:
			var current_vel = Vector2(velocity.x, velocity.z).length()
			var dir = -collision.get_normal()
			dir.y = push_up
			var contact_point = collision.get_position() - collider.global_position
			var force = max(current_vel, 3.0)
			collider.apply_impulse(dir.normalized() * force * push_force, contact_point)
		# Kolla om det är kungen och vi stångar
		elif collider.has_method("die") and is_rodding:
			collider.die()

	# Locomotion blend
	if not is_jumping and not is_emoting and not emote_frozen and not is_rodding:
		var current_velocity = Vector2(velocity.x, velocity.z).length()
		var blend = 0.0
		if current_velocity > 0.1:
			blend = clamp(remap(current_velocity, 0.0, run_speed, 0.0, 1.0), 0.0, 1.0)
		anim_tree.set("parameters/StateMachine/locomotion/blend_position", blend)
