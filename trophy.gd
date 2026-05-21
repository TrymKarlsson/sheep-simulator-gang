extends Area3D

var collected = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if collected:
		return
	if body is CharacterBody3D:
		collected = true
		TrophyManager.collect()
		queue_free()
