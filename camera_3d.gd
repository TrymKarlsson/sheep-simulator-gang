extends Camera3D

@export var target: Node3D
@export var distance = 6.0
@export var height = 3.0
@export var smoothness = 5.0
@export var rotation_smoothness = 3.0
@export var look_at_offset = Vector3(0, 1.5, 0)
@export var mouse_sensitivity = 0.3
@export var min_pitch = -80.0
@export var max_pitch = 60.0

var pivot: Node3D
var smooth_forward: Vector3 = Vector3.BACK
var yaw_offset = 0.0
var pitch_offset = 0.0
var is_mouse_free = false

func _ready():
	pivot = target.get_node("Pivot")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	smooth_forward = -pivot.global_transform.basis.z

func _input(event):
	if event is InputEventMouseMotion and not is_mouse_free:
		yaw_offset -= event.relative.x * mouse_sensitivity
		pitch_offset -= event.relative.y * mouse_sensitivity
		pitch_offset = clamp(pitch_offset, min_pitch, max_pitch)

func _process(delta):
	if not target or not pivot:
		return

	# Frigör musen när emote wheel är uppe
	if Input.is_action_pressed("EmoteWheel"):
		if not is_mouse_free:
			is_mouse_free = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		if is_mouse_free:
			is_mouse_free = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Återställ yaw när spelaren rör sig så kameran följer efter
	var is_moving = Input.is_action_pressed("Forward") or Input.is_action_pressed("Backwards") or \
					Input.is_action_pressed("Left") or Input.is_action_pressed("Right")
	if is_moving:
		yaw_offset = lerp(yaw_offset, 0.0, rotation_smoothness * delta)

	# Använd pivot-riktningen som bas
	var forward = -pivot.global_transform.basis.z
	smooth_forward = smooth_forward.lerp(forward, rotation_smoothness * delta).normalized()

	# Applicera yaw och pitch
	var yaw_rot = Basis(Vector3.UP, deg_to_rad(yaw_offset))
	var rotated_forward = yaw_rot * smooth_forward

	var right = rotated_forward.cross(Vector3.UP).normalized()
	var pitch_rot = Basis(right, deg_to_rad(pitch_offset))
	var final_forward = pitch_rot * rotated_forward

	var desired_pos = target.global_position - final_forward * distance + Vector3.UP * height
	global_position = global_position.lerp(desired_pos, smoothness * delta)
	look_at(target.global_position + look_at_offset)
