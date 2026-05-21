extends RigidBody3D

@export var bounce_factor = 1.0  # Hur mycket extra kraft vid kollision

func _ready():
	# Gör blocket lite studsigt
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.bounce = 0.4
	physics_material_override.friction = 0.8
