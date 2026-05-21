extends Node3D

@export var bob_height = 0.1
@export var bob_speed = 2.0
@export var rotation_speed = 1.0

var start_y: float
var time = 0.0

func _ready():
	start_y = position.y

func _process(delta):
	time += delta
	# Bob upp och ned
	position.y = start_y + sin(time * bob_speed) * bob_height
	# Rotera på Y-axeln (ser snyggare ut än X)
	rotation.y += rotation_speed * delta
