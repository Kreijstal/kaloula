@tool
class_name PlayerCard
extends HBoxContainer
## One player in the HUD dock (player_card.tscn): paint can with the mini frog, name,
## score, paint left. Edit the layout and fonts in the scene; the HUD fills in the values.

## Can on the right and text right-aligned (for the right-hand player).
@export var mirrored := false:
	set(v):
		mirrored = v
		if is_node_ready():
			_apply_mirrored()

@onready var can: PaintCan = $Can
@onready var name_label: Label = $Text/Name
@onready var score_label: Label = $Text/Score
@onready var paint_label: Label = $Text/Paint

var _paint_left := -1
var _paint_max := 20


func _ready() -> void:
	_apply_mirrored()


func set_player(display_name: String, color: Color) -> void:
	name_label.text = display_name.to_upper()
	name_label.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.55))


func set_score(points: int) -> void:
	score_label.text = str(points)
	_refresh_paint_label()


func set_paint(left: int, max_paint: int) -> void:
	_paint_left = left
	_paint_max = maxi(max_paint, 1)
	can.level = clampf(float(left) / _paint_max, 0.0, 1.0)
	_refresh_paint_label()


func _refresh_paint_label() -> void:
	if _paint_left < 0:
		paint_label.text = "points"
	elif _paint_left > _paint_max:
		paint_label.text = "points · lots of paint"
	else:
		paint_label.text = "points · %d of %d paint" % [_paint_left, _paint_max]


func _apply_mirrored() -> void:
	var text: Control = $Text
	alignment = BoxContainer.ALIGNMENT_END if mirrored else BoxContainer.ALIGNMENT_BEGIN
	move_child(text, 0 if mirrored else 1)
	var align := HORIZONTAL_ALIGNMENT_RIGHT if mirrored else HORIZONTAL_ALIGNMENT_LEFT
	for l in text.get_children():
		if l is Label:
			l.horizontal_alignment = align
