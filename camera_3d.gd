extends Camera3D

@export var target: Node3D
@export var distance = 6.0
@export var height = 3.0
@export var smoothness = 5.0
@export var rotation_smoothness = 3.0
@export var look_at_offset = Vector3(0, 1.5, 0)

var pivot: Node3D
var smooth_forward: Vector3 = Vector3.BACK

func _ready():
	pivot = target.get_node("Pivot")

func _process(delta):
	if not target or not pivot:
		return
	
	var forward = -pivot.global_transform.basis.z
	# Smoothar riktningen istället för att snappa direkt
	smooth_forward = smooth_forward.lerp(forward, rotation_smoothness * delta).normalized()
	
	var desired_pos = target.global_position - smooth_forward * distance + Vector3.UP * height
	global_position = global_position.lerp(desired_pos, smoothness * delta)
	look_at(target.global_position + look_at_offset)
