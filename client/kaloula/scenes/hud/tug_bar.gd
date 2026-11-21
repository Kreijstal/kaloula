class_name TugBar
extends Control
## Tug-of-war bar: one coloured segment per player, unpainted tiles in the middle.
## The first players fill from the left, the last one from the right.

@export var unpainted_color := Color("e8e4d2")
@export var edge_color := Color("0b0f0e")
@export var tick_color := Color("1c2423")
## How fast the segments slide to new values (higher = snappier).
@export var smoothing := 8.0

var _colors: Array[Color] = []
var _target: Array[float] = []
var _shown: Array[float] = []
var _target_empty := 0.0
var _shown_empty := 0.0


## `colors[i]` and `values[i]` per player, in bar order; `unpainted` = tiles nobody has.
func set_values(colors: Array[Color], values: Array[float], unpainted: float) -> void:
	if colors.size() != _colors.size():
		_shown = values.duplicate()
		_shown_empty = unpainted
	_colors = colors
	_target = values
	_target_empty = unpainted
	queue_redraw()


func _process(delta: float) -> void:
	var k := 1.0 - exp(-smoothing * delta)
	var moving := false
	for i in _shown.size():
		var before := _shown[i]
		_shown[i] = lerpf(_shown[i], _target[i], k)
		moving = moving or absf(before - _shown[i]) > 0.001
	var before_empty := _shown_empty
	_shown_empty = lerpf(_shown_empty, _target_empty, k)
	if moving or absf(before_empty - _shown_empty) > 0.001:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var total := _shown_empty
	for v in _shown:
		total += v
	# drop shadow and bottom edge
	draw_rect(Rect2(0, h, w, 4), Color(0, 0, 0, 0.25))
	if total <= 0.0:
		_segment(0.0, w, unpainted_color, 0.1)
	else:
		var n := _colors.size()
		var x := 0.0
		for i in maxi(n - 1, 0):
			var sw := w * _shown[i] / total
			_segment(x, sw, _colors[i], 0.25)
			x += sw
		var right := w * _shown[n - 1] / total if n > 0 else 0.0
		_segment(x, w - x - right, unpainted_color, 0.1)
		if n > 0:
			_segment(w - right, right, _colors[n - 1], 0.25)
	draw_rect(Rect2(0, h - 3, w, 3), edge_color)
	# centre mark
	draw_rect(Rect2(w * 0.5 - 1.5, 0, 3, h + 14), tick_color)


func _segment(x: float, width: float, color: Color, shade: float) -> void:
	if width <= 0.0:
		return
	draw_rect(Rect2(x, 0, width, size.y), color)
	draw_rect(Rect2(x, size.y - 8, width, 5), Color(0, 0, 0, shade))
