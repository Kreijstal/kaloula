@tool
class_name TugBar
extends Control
## Tug-of-war bar: one coloured segment per player, sized by their share of the total score.

@export var edge_color := Color("0b0f0e")
@export var tick_color := Color("1c2423")
## How fast the segments slide to new values (higher = snappier).
@export var smoothing := 8.0
## Colours drawn (in equal parts) until the HUD sets real values, e.g. in the editor.
@export var preview_colors: Array[Color] = [Color("2f4cf5"), Color("d6332b")]

var _colors: Array[Color] = []
var _target: Array[float] = []
var _shown: Array[float] = []


## `colors[i]` and `scores[i]` per player, in bar order. Equal shares while nobody has scored.
func set_values(colors: Array[Color], scores: Array[float]) -> void:
	assert(colors.size() == scores.size(), "TugBar got %d colours for %d scores" % [colors.size(), scores.size()])
	var total := 0.0
	for s in scores:
		assert(s >= 0.0, "TugBar scores must be non-negative, got %s" % [scores])
		total += s
	var shares: Array[float] = []
	for s in scores:
		shares.append(s / total if total > 0.0 else 1.0 / scores.size())
	if colors.size() != _colors.size():
		_shown = shares.duplicate()
	_colors = colors
	_target = shares
	queue_redraw()


func _process(delta: float) -> void:
	var k := 1.0 - exp(-smoothing * delta)
	var moving := false
	for i in _shown.size():
		var before := _shown[i]
		_shown[i] = lerpf(_shown[i], _target[i], k)
		moving = moving or absf(before - _shown[i]) > 0.0001
	if moving:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	# drop shadow and bottom edge
	draw_rect(Rect2(0, h, w, 4), Color(0, 0, 0, 0.25))
	var colors := _colors
	var shown := _shown
	if colors.is_empty():
		colors = preview_colors
		shown = []
		for c in colors:
			shown.append(1.0 / colors.size())
	var x := 0.0
	for i in colors.size():
		# the last segment takes whatever is left, so rounding never leaves a gap
		var sw := w - x if i == colors.size() - 1 else w * shown[i]
		_segment(x, sw, colors[i])
		x += sw
	draw_rect(Rect2(0, h - 3, w, 3), edge_color)
	# centre mark
	draw_rect(Rect2(w * 0.5 - 1.5, 0, 3, h + 14), tick_color)


func _segment(x: float, width: float, color: Color) -> void:
	if width <= 0.0:
		return
	draw_rect(Rect2(x, 0, width, size.y), color)
	draw_rect(Rect2(x, size.y - 8, width, 5), Color(0, 0, 0, 0.25))
