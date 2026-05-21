extends Control
var selected = ""
var emotes = {
	"up": "belly_rub_emote",
	"down": "stand_to_sitting_emote",
	"left": "alert_emote",
	"right": "death_emote"
}
var emote_labels = {
	"up": "Belly Rub",
	"down": "Sit",
	"left": "Alert",
	"right": "Fake Death"
}

func _ready():
	hide()

func _draw():
	if not visible:
		return
	var center = get_viewport_rect().size / 2
	var radius = 120.0
	var inner = 40.0
	draw_circle(center, radius, Color(0, 0, 0, 0.6))
	draw_circle(center, inner, Color(0, 0, 0, 0.8))
	var dirs = {"up": Vector2(0, -80), "down": Vector2(0, 80),
				"left": Vector2(-80, 0), "right": Vector2(80, 0)}
	for key in dirs:
		var col = Color(1, 1, 1, 0.9) if key == selected else Color(0.6, 0.6, 0.6, 0.7)
		var pos = center + dirs[key]
		draw_circle(pos, 30, col)
		var font = ThemeDB.fallback_font
		var label = emote_labels[key]
		var text_pos = pos + Vector2(-font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x / 2, 6)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0, 0, 0))

func _process(_delta):
	if not visible:
		return
	queue_redraw()
	var center = get_viewport_rect().size / 2
	var mouse = get_viewport().get_mouse_position()
	var dir = mouse - center
	if dir.length() > 50:
		if abs(dir.x) > abs(dir.y):
			selected = "right" if dir.x > 0 else "left"
		else:
			selected = "down" if dir.y > 0 else "up"
	else:
		selected = ""

func get_selected_emote() -> String:
	return emotes.get(selected, "")
