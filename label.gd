extends Label

func _ready():
	TrophyManager.trophy_collected.connect(_on_trophy_collected)
	modulate.a = 0.0
	anchors_preset = Control.PRESET_CENTER
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 64)

func _on_trophy_collected(count: int):
	text = str(count) + "/10 trophies hittade"
	# Avbryt eventuell pågående animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_interval(3.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
