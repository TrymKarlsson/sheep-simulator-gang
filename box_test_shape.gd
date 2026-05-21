extends RigidBody3D

@export var bounce_factor = 1.0

func _ready():
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.6
	physics_material_override.friction = 0.3
