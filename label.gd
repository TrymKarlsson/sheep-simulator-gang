extends Label

func _ready():
	TrophyManager.trophy_collected.connect(_on_trophy_collected)
	visible = false

func _on_trophy_collected(count: int):
	text = str(count) + "/10"
	visible = true
	await get_tree().create_timer(2.0).timeout
	visible = false
